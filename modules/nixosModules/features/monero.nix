{
  flake.nixosModules.monero =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        getExe'
        mkIf
        mkMerge
        mkOption
        mkEnableOption
        optionalString
        types
        ;

      cfg = config.monero;
      monerod = getExe' pkgs.monero-cli "monerod";
    in
    {
      options.monero = {
        node = {
          enable = mkEnableOption "the Monero P2P node (monerod)";

          dataDir = mkOption {
            type = types.str;
            default = "/var/lib/monero";
            description = "Directory for the Monero blockchain LMDB database.";
          };

          prune = mkOption {
            type = types.bool;
            default = false;
            description = "Run monerod in pruned mode to reduce disk usage.";
          };

          rpcAddress = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Address the monerod JSON-RPC binds to.";
          };

          rpcPort = mkOption {
            type = types.port;
            default = 18081;
            description = "Port for the monerod JSON-RPC.";
          };

          zmqPort = mkOption {
            type = types.port;
            default = 18082;
            description = "Port for the monerod ZMQ pub-sub.";
          };

          p2pAddress = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = "Address the monerod P2P server binds to.";
          };

          p2pPort = mkOption {
            type = types.port;
            default = 18080;
            description = "Port for the monerod P2P server.";
          };

          limitRateUp = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Upload rate limit in KiB/s. Null = unlimited.";
          };

          limitRateDown = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Download rate limit in KiB/s. Null = unlimited.";
          };

          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional command-line flags passed to monerod.";
          };
        };

        gui = {
          enable = mkEnableOption "the Monero GUI wallet (monero-wallet-gui)" // {
            default = true;
          };

          package = mkOption {
            type = types.package;
            default = pkgs.monero-gui;
            defaultText = lib.literalExpression "pkgs.monero-gui";
            description = "Package providing the Monero Qt wallet GUI.";
          };
        };

        mining = {
          enable = mkEnableOption "the XMRig miner service";

          pool = mkOption {
            type = types.str;
            default = "pool.supportxmr.com:443";
            description = "URL of the Monero mining pool.";
          };

          wallet = mkOption {
            type = types.str;
            description = "Wallet address for mining reward payouts.";
          };

          maxUsagePercentage = mkOption {
            type = types.ints.between 1 100;
            default = 100;
            description = "CPU usage hint forwarded to XMRig (1-100).";
          };
        };
      };

      config = mkMerge [
        (mkIf cfg.gui.enable {
          environment.systemPackages = [ cfg.gui.package ];
        })

        (mkIf cfg.node.enable {
          environment.systemPackages = [ pkgs.monero-cli ];

          users = {
            users.monero = {
              isSystemUser = true;
              group = "monero";
              home = cfg.node.dataDir;
            };

            groups.monero = { };
          };

          systemd.tmpfiles.rules = [
            "d ${cfg.node.dataDir} 0700 monero monero - -"
          ];

          systemd.services.monerod = {
            description = "Monero P2P node";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            preStart = ''
              # Disable btrfs copy-on-write on the data directory to prevent
              # LMDB-induced metadata exhaustion and read-only remounts.
              if command -v chattr &> /dev/null; then
                chattr +C ${cfg.node.dataDir} 2>/dev/null || true
              fi
            '';

            serviceConfig = {
              Type = "simple";
              User = "monero";
              Group = "monero";
              ExecStart = ''
                ${monerod} \
                  --data-dir ${cfg.node.dataDir} \
                  --rpc-bind-ip ${cfg.node.rpcAddress} \
                  --rpc-bind-port ${toString cfg.node.rpcPort} \
                  --p2p-bind-ip ${cfg.node.p2pAddress} \
                  --p2p-bind-port ${toString cfg.node.p2pPort} \
                  --zmq-rpc-bind-ip ${cfg.node.rpcAddress} \
                  --zmq-rpc-bind-port ${toString cfg.node.zmqPort} \
                  ${optionalString cfg.node.prune "--prune-blockchain"} \
                  ${
                    optionalString (cfg.node.limitRateUp != null) "--limit-rate-up ${toString cfg.node.limitRateUp}"
                  } \
                  ${
                    optionalString (
                      cfg.node.limitRateDown != null
                    ) "--limit-rate-down ${toString cfg.node.limitRateDown}"
                  } \
                  ${toString cfg.node.extraArgs}
              '';
              Restart = "on-failure";
              RestartSec = "30s";
              PrivateDevices = true;
              ProtectSystem = "full";
              ProtectHome = true;
              NoNewPrivileges = true;
              LimitNOFILE = 65536;
            };
          };
        })

        (mkIf cfg.mining.enable {
          assertions = [
            {
              assertion = cfg.mining.maxUsagePercentage >= 1 && cfg.mining.maxUsagePercentage <= 100;
              message = "monero.mining.maxUsagePercentage must be between 1 and 100.";
            }
          ];

          services.xmrig = {
            enable = true;
            settings = {
              autosave = true;
              opencl = false;
              cuda = false;
              cpu = {
                enabled = true;
                max-threads-hint = cfg.mining.maxUsagePercentage;
              };
              pools = [
                {
                  url = cfg.mining.pool;
                  user = cfg.mining.wallet;
                  keepalive = true;
                  tls = true;
                }
              ];
            };
          };
        })
      ];
    };
}
