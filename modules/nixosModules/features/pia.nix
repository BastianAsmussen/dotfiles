{
  flake.nixosModules.pia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe
        getExe'
        escapeShellArg
        listToAttrs
        mkEnableOption
        mkIf
        mkOption
        types
        ;

      cfg = config.pia;

      baseHardening = {
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateIPC = true;
        ProtectKernelTunables = true;
        ProtectKernelLogs = true;
        ProtectClock = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
      };

      curl = getExe pkgs.curl;
      ip = getExe' pkgs.iproute2 "ip";
      jq = getExe pkgs.jq;
      mktemp = getExe' pkgs.coreutils "mktemp";
      rm = getExe' pkgs.coreutils "rm";
      sleep = getExe' pkgs.coreutils "sleep";
      wg = getExe' pkgs.wireguard-tools "wg";

      piaCaCert = lib.custom.keys.selectCertPath "pia-ca.rsa.4096.crt" lib.custom.keys.default;

      qbtUser = config.services.qbittorrent.user;

      connectScript = pkgs.writeShellScript "pia-connect" ''
        set -euo pipefail

        PIA_USER="$(cat ${escapeShellArg config.sops.secrets."services/pia/username".path})"
        PIA_PASS="$(cat ${escapeShellArg config.sops.secrets."services/pia/password".path})"
        INTERFACE=${escapeShellArg cfg.interface}
        REGION=${escapeShellArg cfg.region}
        TABLE=${toString cfg.routeTable}
        CA_CERT=${piaCaCert}
        STATE_DIR=/run/pia
        QBT_UID="$(id -u ${escapeShellArg qbtUser})"

        log() { echo "[pia-connect] $*"; }

        ${ip} rule del uidrange "$QBT_UID-$QBT_UID" to 127.0.0.0/8 table main priority 50 2>/dev/null || true
        ${ip} rule del uidrange "$QBT_UID-$QBT_UID" table "$TABLE" priority 100 2>/dev/null || true
        ${ip} route flush table "$TABLE" 2>/dev/null || true
        ${ip} -6 rule del uidrange "$QBT_UID-$QBT_UID" to ::1/128 table main priority 50 2>/dev/null || true
        ${ip} -6 rule del uidrange "$QBT_UID-$QBT_UID" unreachable priority 100 2>/dev/null || true

        log "Acquiring PIA token..."
        TOKEN="$(${curl} -s --max-time 30 --retry 5 --retry-delay 2 \
          -X POST "https://www.privateinternetaccess.com/api/client/v2/token" \
          --data-urlencode "username=$PIA_USER" \
          --data-urlencode "password=$PIA_PASS" \
          | ${jq} -r '.token')"
        [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ] || { echo "Failed to acquire PIA token" >&2; exit 1; }

        log "Fetching server list..."
        SERVERS="$(${curl} -s --max-time 30 --retry 5 --retry-delay 2 \
          "https://serverlist.piaservers.net/vpninfo/servers/v6" | head -1)"
        read -r WG_HOSTNAME WG_IP <<< \
          "$(printf '%s' "$SERVERS" | ${jq} -r ".regions[] | select(.id == \"$REGION\") | [.servers.wg[0].cn, .servers.wg[0].ip] | @tsv")"
        [ -n "$WG_HOSTNAME" ] && [ "$WG_HOSTNAME" != "null" ] || { echo "Region '$REGION' not found in server list" >&2; exit 1; }
        log "Server: $WG_HOSTNAME ($WG_IP)"

        PRIVKEY="$(${wg} genkey)"
        PUBKEY="$(printf '%s' "$PRIVKEY" | ${wg} pubkey)"

        log "Registering WireGuard key with PIA..."
        WG_INFO="$(${curl} -sG --max-time 30 \
          --connect-to "$WG_HOSTNAME::$WG_IP:" \
          --cacert "$CA_CERT" \
          "https://$WG_HOSTNAME:1337/addKey" \
          --data-urlencode "pt=$TOKEN" \
          --data-urlencode "pubkey=$PUBKEY")"
        [ "$(printf '%s' "$WG_INFO" | ${jq} -r '.status')" = "OK" ] || { echo "addKey failed: $WG_INFO" >&2; exit 1; }

        read -r PEER_IP SERVER_KEY SERVER_PORT VPN_GW VPN_DNS <<< \
          "$(printf '%s' "$WG_INFO" | ${jq} -r '[.peer_ip, .server_key, .server_port, .server_vip, (.dns_servers[0] // "")] | @tsv')"
        [ -n "$VPN_DNS" ] || { echo "PIA returned no DNS server" >&2; exit 1; }
        log "Peer IP: $PEER_IP, Gateway: $VPN_GW"

        ${ip} link del dev "$INTERFACE" 2>/dev/null || true
        ${ip} link add dev "$INTERFACE" type wireguard
        ${ip} link set "$INTERFACE" mtu 1420
        ${wg} set "$INTERFACE" \
          private-key <(printf '%s' "$PRIVKEY") \
          fwmark "$TABLE" \
          peer "$SERVER_KEY" \
          endpoint "$WG_IP:$SERVER_PORT" \
          allowed-ips "0.0.0.0/0" \
          persistent-keepalive 25
        ${ip} addr add "$PEER_IP/32" dev "$INTERFACE"
        ${ip} link set up dev "$INTERFACE"
        ${ip} route add "$VPN_GW" dev "$INTERFACE"
        log "Interface $INTERFACE up"

        ${ip} route add "$VPN_DNS/32" dev "$INTERFACE"
        printf '%s' "$VPN_DNS" > "$STATE_DIR/dns"
        printf 'nameserver %s\n' "$VPN_DNS" > "$STATE_DIR/resolv.conf"
        log "DNS via PIA: $VPN_DNS"

        ${ip} rule add uidrange "$QBT_UID-$QBT_UID" to 127.0.0.0/8 table main priority 50
        ${ip} rule add uidrange "$QBT_UID-$QBT_UID" table "$TABLE" priority 100
        ${ip} route add default dev "$INTERFACE" table "$TABLE"
        ${ip} -6 rule add uidrange "$QBT_UID-$QBT_UID" to ::1/128 table main priority 50
        ${ip} -6 rule add uidrange "$QBT_UID-$QBT_UID" unreachable priority 100
        log "Kill switch active (UID $QBT_UID via $INTERFACE)"

        # Tries validated hostname first; falls back to bare VPN_GW without TLS verification.
        pf_api() {
          local path="$1"; shift
          ${curl} -sG --max-time 30 --interface "$INTERFACE" \
            --connect-to "$WG_HOSTNAME::$VPN_GW:" --cacert "$CA_CERT" \
            "https://$WG_HOSTNAME:19999/$path" "$@" 2>/dev/null || \
          ${curl} -sG --max-time 30 --interface "$INTERFACE" --insecure \
            "https://$VPN_GW:19999/$path" "$@"
        }

        log "Requesting port forwarding signature..."
        PF_RESPONSE="$(pf_api getSignature --data-urlencode "token=$TOKEN")"
        [ "$(printf '%s' "$PF_RESPONSE" | ${jq} -r '.status')" = "OK" ] || { echo "getSignature failed: $PF_RESPONSE" >&2; exit 1; }

        read -r PF_PAYLOAD PF_SIGNATURE PF_PORT <<< \
          "$(printf '%s' "$PF_RESPONSE" | ${jq} -r '[.payload, .signature, (.payload | @base64d | fromjson | .port | tostring)] | @tsv')"

        printf '%s' "$PF_PAYLOAD"   > "$STATE_DIR/payload"
        printf '%s' "$PF_SIGNATURE" > "$STATE_DIR/signature"
        printf '%s' "$VPN_GW"       > "$STATE_DIR/gateway"
        printf '%s' "$WG_HOSTNAME"  > "$STATE_DIR/hostname"
        printf '%s' "$PF_PORT"      > "$STATE_DIR/port"

        BIND_RESPONSE="$(pf_api bindPort --data-urlencode "payload=$PF_PAYLOAD" --data-urlencode "signature=$PF_SIGNATURE")"
        [ "$(printf '%s' "$BIND_RESPONSE" | ${jq} -r '.status')" = "OK" ] || { echo "bindPort failed: $BIND_RESPONSE" >&2; exit 1; }

        log "VPN active. Port forwarding on port $PF_PORT."
      '';

      disconnectScript = pkgs.writeShellScript "pia-disconnect" ''
        set -euo pipefail
        INTERFACE=${escapeShellArg cfg.interface}
        TABLE=${toString cfg.routeTable}
        QBT_UID="$(id -u ${escapeShellArg qbtUser} 2>/dev/null || echo 0)"

        log() { echo "[pia-disconnect] $*"; }

        [ ! -f /run/pia/dns ] || ${ip} route del "$(cat /run/pia/dns)/32" dev "$INTERFACE" 2>/dev/null || true
        ${ip} route flush table "$TABLE" 2>/dev/null || true
        ${ip} rule del uidrange "$QBT_UID-$QBT_UID" to 127.0.0.0/8 table main priority 50 2>/dev/null || true
        ${ip} rule del uidrange "$QBT_UID-$QBT_UID" table "$TABLE" priority 100 2>/dev/null || true
        ${ip} -6 rule del uidrange "$QBT_UID-$QBT_UID" to ::1/128 table main priority 50 2>/dev/null || true
        ${ip} -6 rule del uidrange "$QBT_UID-$QBT_UID" unreachable priority 100 2>/dev/null || true
        ${ip} link del dev "$INTERFACE" 2>/dev/null || true
        log "Interface $INTERFACE removed"
      '';

      portForwardScript = pkgs.writeShellScript "pia-port-forward" ''
        set -euo pipefail
        INTERFACE=${escapeShellArg cfg.interface}
        STATE_DIR=/run/pia

        PF_PAYLOAD="$(cat "$STATE_DIR/payload")"
        PF_SIGNATURE="$(cat "$STATE_DIR/signature")"
        VPN_GW="$(cat "$STATE_DIR/gateway")"
        PORT="$(cat "$STATE_DIR/port")"

        RESPONSE="$(${curl} -sG --max-time 30 \
          --interface "$INTERFACE" \
          --insecure \
          "https://$VPN_GW:19999/bindPort" \
          --data-urlencode "payload=$PF_PAYLOAD" \
          --data-urlencode "signature=$PF_SIGNATURE")"
        STATUS="$(printf '%s' "$RESPONSE" | ${jq} -r '.status')"
        [ "$STATUS" = "OK" ] || { echo "bindPort failed: $RESPONSE" >&2; exit 1; }
        echo "[pia-port-forward] Port $PORT lease renewed"
      '';

      syncPortScript = pkgs.writeShellScript "pia-sync-port" ''
        set -euo pipefail

        PORT="$(cat /run/pia/port)"
        QBT_PASS="$(cat ${escapeShellArg cfg.portSync.passwordFile})"
        BASE_URL="http://${cfg.portSync.address}:${toString cfg.portSync.port}"
        COOKIE_JAR="$(${mktemp} -t pia-sync-cookies.XXXXXX)"
        trap '${rm} -f "$COOKIE_JAR"' EXIT

        login() {
          ${curl} -sS -o /dev/null -w "%{http_code}" \
            -c "$COOKIE_JAR" \
            -H "Referer: $BASE_URL" \
            --data-urlencode ${escapeShellArg "username=${cfg.portSync.username}"} \
            --data-urlencode "password=$QBT_PASS" \
            "$BASE_URL/api/v2/auth/login"
        }

        for attempt in {1..60}; do
          status="$(login 2>/dev/null || true)"
          case "$status" in
            200|204) break;;
          esac
          if [ "$attempt" -eq 60 ]; then
            echo "qBittorrent WebUI authentication failed (HTTP $status)" >&2
            exit 1
          fi
          ${sleep} 1
        done

        STATUS="$(${curl} -sS -o /dev/null -w "%{http_code}" -X POST \
          -b "$COOKIE_JAR" \
          -H "Referer: $BASE_URL" \
          --data-urlencode "json={\"listen_port\": $PORT}" \
          "$BASE_URL/api/v2/app/setPreferences")"
        case "$STATUS" in
          200) echo "[pia-sync-port] Set qBittorrent listen port to $PORT";;
          *) echo "Failed to set listen port (HTTP $STATUS)" >&2; exit 1;;
        esac
      '';

    in
    {
      options.pia = {
        enable = mkEnableOption "PIA WireGuard VPN";

        region = mkOption {
          type = types.str;
          default = "nl_amsterdam";
          description = "PIA region ID (e.g. \"nl_amsterdam\", \"us_east\").";
        };

        interface = mkOption {
          type = types.str;
          default = "pia0";
          description = "WireGuard interface name for the PIA tunnel.";
        };

        routeTable = mkOption {
          type = types.int;
          default = 100;
          description = "Policy routing table used to route bound-service traffic through the VPN.";
        };

        boundServices = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "systemd service names (without .service suffix) that must not run without the PIA tunnel.";
        };

        portSync = {
          address = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Address of the qBittorrent WebUI.";
          };

          port = mkOption {
            type = types.port;
            default = 8081;
            description = "Port of the qBittorrent WebUI.";
          };

          username = mkOption {
            type = types.str;
            default = "admin";
            description = "qBittorrent WebUI username for port sync.";
          };

          passwordFile = mkOption {
            type = types.str;
            description = "Path to a file containing the plaintext qBittorrent WebUI password.";
          };
        };
      };

      config = mkIf cfg.enable (
        lib.mkMerge [
          {
            sops.secrets = {
              "services/pia/username" = { };
              "services/pia/password" = { };
            };

            services.resolved.enable = lib.mkDefault true;

            networking = {
              firewall = {
                checkReversePath = lib.mkForce "loose";
                trustedInterfaces = [ cfg.interface ];
              };

              nftables = {
                enable = true;
                checkRuleset = false;
                tables."pia-kill-switch" = {
                  family = "inet";
                  content = ''
                    chain output {
                      type filter hook output priority filter; policy accept;
                      oifname "lo" accept
                      meta mark ${toString cfg.routeTable} accept
                      meta skuid "${qbtUser}" oifname "${cfg.interface}" accept
                      meta skuid "${qbtUser}" drop
                    }
                  '';
                };
              };
            };

            systemd.services.qbittorrent.serviceConfig = {
              PrivateMounts = true;
              BindReadOnlyPaths = [ "/run/pia/resolv.conf:/etc/resolv.conf" ];
            };

            systemd.timers.pia-port-forward = {
              description = "Periodically renew PIA port forwarding lease";
              partOf = [ "pia-connect.service" ];

              timerConfig = {
                OnActiveSec = "14min";
                OnUnitActiveSec = "14min";
              };
            };
          }

          {
            systemd.services =
              listToAttrs (
                map (svcName: {
                  name = svcName;
                  value = {
                    after = [ "pia-connect.service" ];
                    requires = [ "pia-connect.service" ];
                    partOf = [ "pia-connect.service" ];
                  };
                }) cfg.boundServices
              )
              // {
                pia-connect = {
                  description = "PIA WireGuard VPN connection";
                  wantedBy = [ "multi-user.target" ];
                  after = [
                    "network-online.target"
                    "sops-install-secrets.service"
                  ];
                  wants = [
                    "network-online.target"
                    "pia-port-forward.timer"
                    "pia-sync-port.service"
                  ];

                  serviceConfig = baseHardening // {
                    Type = "oneshot";
                    RemainAfterExit = true;
                    RuntimeDirectory = "pia";
                    RuntimeDirectoryMode = "0700";
                    ExecStart = connectScript;
                    ExecStop = disconnectScript;
                    CapabilityBoundingSet = "CAP_NET_ADMIN";
                    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX AF_NETLINK";
                    ProtectSystem = "strict";
                    ProtectHome = true;
                  };
                };

                pia-port-forward = {
                  description = "Renew PIA port forwarding lease";
                  after = [ "pia-connect.service" ];
                  requires = [ "pia-connect.service" ];

                  serviceConfig = baseHardening // {
                    Type = "oneshot";
                    ExecStart = portForwardScript;
                    ExecStartPost = syncPortScript;
                    # CAP_DAC_READ_SEARCH: read the qbt WebUI password (sops secret owned by qbittorrent user)
                    CapabilityBoundingSet = "CAP_DAC_READ_SEARCH";
                    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
                  };
                };

                pia-sync-port = {
                  description = "Sync PIA forwarded port to qBittorrent";
                  after = [ "pia-connect.service" ] ++ map (s: "${s}.service") cfg.boundServices;
                  requires = [ "pia-connect.service" ] ++ map (s: "${s}.service") cfg.boundServices;
                  serviceConfig = baseHardening // {
                    Type = "oneshot";
                    ExecStart = syncPortScript;
                    # CAP_DAC_READ_SEARCH: read the qbt WebUI password (sops secret owned by qbittorrent user)
                    CapabilityBoundingSet = "CAP_DAC_READ_SEARCH";
                    RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
                  };
                };
              };
          }
        ]
      );
    };
}
