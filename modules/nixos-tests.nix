{
  self,
  inputs,
  ...
}:
let
  # Evaluate NixOS modules without booting a VM.
  evalNixos =
    modules:
    (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit self inputs;
        inherit (self) lib;

        outputs = self;
      };

      inherit modules;
    }).config;

  # Override nix-secrets-derived defaults so eval tests are hermetic.
  testUser = {
    preferences.user = {
      name = "testuser";
      fullName = "Test User";
      email = "test@example.com";
    };
  };
in
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      mkEvalTest =
        name: modules: assertFn:
        let
          cfg = evalNixos modules;
          ok = assertFn cfg;
        in
        assert lib.assertMsg ok "nixos-eval-${name}: assertion failed";
        pkgs.runCommandLocal "nixos-eval-${name}" { } "touch $out";

      # Self-signed CA and client certificate for the mTLS listener.
      mtlsCerts =
        pkgs.runCommand "mtls-certs"
          {
            nativeBuildInputs = [ pkgs.openssl ];
          }
          ''
            openssl req -x509 -newkey rsa:2048 -keyout ca.key -out ca.crt -days 3650 -nodes -subj "/CN=test-ca"
            openssl req -newkey rsa:2048 -keyout client.key -out client.csr -nodes -subj "/CN=test-client"
            openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 3650
            mkdir $out
            cp ca.crt ca.key client.crt client.key $out
          '';

      # Echoes every request header back as the response body.
      headerEcho = pkgs.writers.writePython3 "header-echo" { } ''
        import http.server


        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                body = "".join(
                    f"{field}: {value}\n" for field, value in self.headers.items()
                ).encode()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, format, *args):
                pass


        http.server.ThreadingHTTPServer(("127.0.0.1", 8096), Handler).serve_forever()
      '';

      # Stands in for the gaming module so primaryBusy's hook options exist.
      gamemodeStub =
        { lib, ... }:
        {
          options.gamemode = {
            startHooks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Commands to run when a gamemode session starts.";
            };

            endHooks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Commands to run when a gamemode session ends.";
            };
          };
        };
    in
    {
      checks = {
        # `preferences.monitors` Option Tests.
        nixos-eval-monitors-default-empty = mkEvalTest "monitors-default-empty" [
          self.nixosModules.base
          testUser
        ] (cfg: cfg.preferences.monitors == { });

        nixos-eval-monitor-vrr-default-off = mkEvalTest "monitor-vrr-default-off" [
          self.nixosModules.base
          testUser
          {
            preferences.monitors.DP-1 = {
              width = 1920;
              height = 1080;
            };
          }
        ] (cfg: cfg.preferences.monitors.DP-1.vrr == "off");

        nixos-eval-monitor-scale-default-one = mkEvalTest "monitor-scale-default-one" [
          self.nixosModules.base
          testUser
          {
            preferences.monitors.DP-1 = {
              width = 1920;
              height = 1080;
            };
          }
        ] (cfg: cfg.preferences.monitors.DP-1.scale == 1.0);

        nixos-eval-monitor-enabled-default-true = mkEvalTest "monitor-enabled-default-true" [
          self.nixosModules.base
          testUser
          {
            preferences.monitors.DP-1 = {
              width = 1920;
              height = 1080;
            };
          }
        ] (cfg: cfg.preferences.monitors.DP-1.enabled);

        nixos-eval-monitor-disabled-flag = mkEvalTest "monitor-disabled-flag" [
          self.nixosModules.base
          testUser
          {
            preferences.monitors.DP-1 = {
              width = 1920;
              height = 1080;
              enabled = false;
            };
          }
        ] (cfg: !cfg.preferences.monitors.DP-1.enabled);

        # `preferences.user` Option Tests.
        nixos-eval-user-wheel-group = mkEvalTest "user-wheel-group" [ self.nixosModules.base testUser ] (
          cfg: builtins.elem "wheel" cfg.users.users.testuser.extraGroups
        );

        nixos-eval-user-is-normal = mkEvalTest "user-is-normal" [ self.nixosModules.base testUser ] (
          cfg: cfg.users.users.testuser.isNormalUser
        );

        nixos-eval-zsh-system-enabled = mkEvalTest "zsh-system-enabled" [
          self.nixosModules.base
          testUser
        ] (cfg: cfg.programs.zsh.enable);

        nixos-eval-fish-system-enabled = mkEvalTest "fish-system-enabled" [
          self.nixosModules.base
          testUser
        ] (cfg: cfg.programs.fish.enable);

        # SSH Module.
        nixos-eval-ssh-no-password-auth = mkEvalTest "ssh-no-password-auth" [
          self.nixosModules.base
          self.nixosModules.ssh
          testUser
        ] (cfg: !cfg.services.openssh.settings.PasswordAuthentication);

        nixos-eval-ssh-no-root-login = mkEvalTest "ssh-no-root-login" [
          self.nixosModules.base
          self.nixosModules.ssh
          testUser
        ] (cfg: cfg.services.openssh.settings.PermitRootLogin == "no");

        nixos-eval-ssh-pubkey-only = mkEvalTest "ssh-pubkey-only" [
          self.nixosModules.base
          self.nixosModules.ssh
          testUser
        ] (cfg: cfg.services.openssh.settings.AuthenticationMethods == "publickey");

        # Jellyfin Module.
        nixos-eval-jellyfin-security =
          mkEvalTest "jellyfin-security"
            [
              self.nixosModules.base
              self.nixosModules.jellyfin
              testUser
              { jellyfin.enable = true; }
            ]
            (
              cfg:
              builtins.length cfg.services.jellyfin.package.patches == 4
              && lib.any (
                p: lib.hasInfix "unauthenticated-stream-endpoints" (toString p)
              ) cfg.services.jellyfin.package.patches
              && cfg.systemd.services.jellyfin.serviceConfig.MemoryMax == "4G"
              && lib.hasInfix "169.254.0.0/16" cfg.networking.nftables.tables."jellyfin-egress".content
            );

        # Bluetooth Module.
        nixos-eval-bluetooth-enabled = mkEvalTest "bluetooth-enabled" [
          self.nixosModules.base
          self.nixosModules.bluetooth
          testUser
        ] (cfg: cfg.hardware.bluetooth.enable);

        nixos-eval-bluetooth-power-on-boot = mkEvalTest "bluetooth-power-on-boot" [
          self.nixosModules.base
          self.nixosModules.bluetooth
          testUser
        ] (cfg: cfg.hardware.bluetooth.powerOnBoot);
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        # VM tests: runtime behaviour (x86_64 only)
        nixos-vm-jellyfin-patched = pkgs.testers.nixosTest {
          name = "jellyfin-patched";
          nodes.machine =
            { lib, ... }:
            {
              imports = [
                self.nixosModules.base
                self.nixosModules.jellyfin
              ];

              preferences.user = {
                name = lib.mkForce "alice";
                fullName = lib.mkForce "Alice Test";
                email = lib.mkForce "alice@test.com";
                authorizedKeyFiles = [ ];
              };

              jellyfin.enable = true;
              services = {
                meilisearch.enable = lib.mkForce false;
                shoko.enable = lib.mkForce false;
              };

              virtualisation = {
                graphics = false;
                # Jellyfin requires at least 2 GiB of free space in its data directory.
                diskSize = 3 * 1024;
              };
            };

          testScript = ''
            machine.wait_for_unit("jellyfin.service")
            machine.wait_for_open_port(8096)
            machine.wait_until_succeeds("journalctl --since -1m --unit jellyfin --grep 'Startup complete'")
            machine.succeed("curl --fail --silent --max-time 10 http://localhost:8096/System/Info/Public | grep -q 'Jellyfin Server'")

            # Item IDs are predictable, so progressive stream endpoints must
            # reject anonymous requests even for well-formed IDs.
            machine.succeed("test \"$(curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8096/Videos/4774f6f7e4ceff509cc82a6c50bb1b98/stream?static=true')\" = 401")
            machine.succeed("test \"$(curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8096/Audio/4774f6f7e4ceff509cc82a6c50bb1b98/stream?static=true')\" = 401")
            machine.succeed("test \"$(curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8096/Videos/4774f6f7e4ceff509cc82a6c50bb1b98/4774f6f7e4ceff509cc82a6c50bb1b98/Subtitles/0/Stream.vtt')\" = 401")
          '';
        };

        nixos-vm-user-created = pkgs.testers.nixosTest {
          name = "user-created";
          nodes.machine =
            { lib, ... }:
            {
              imports = [ self.nixosModules.base ];
              preferences.user = {
                name = lib.mkForce "alice";
                fullName = lib.mkForce "Alice Test";
                email = lib.mkForce "alice@test.com";
              };

              preferences.user.authorizedKeyFiles = [ ];
              virtualisation.graphics = false;
            };

          testScript = ''
            machine.wait_for_unit("multi-user.target")
            machine.succeed("id alice")
            machine.succeed("id alice | grep -q wheel")
            machine.succeed("getent passwd alice | grep -q fish")
          '';
        };

        nixos-vm-ssh-running = pkgs.testers.nixosTest {
          name = "ssh-running";
          nodes.machine =
            { lib, ... }:
            {
              imports = [
                self.nixosModules.base
                self.nixosModules.ssh
              ];
              preferences.user = {
                name = lib.mkForce "alice";
                fullName = lib.mkForce "Alice Test";
                email = lib.mkForce "alice@test.com";
              };

              preferences.user.authorizedKeyFiles = [ ];
              virtualisation.graphics = false;
            };

          testScript = ''
            machine.wait_for_unit("sshd.service")
            machine.succeed("ss -tlnp | grep -q :22")
          '';
        };

        nixos-vm-caddy-edge = pkgs.testers.nixosTest {
          name = "caddy-edge";
          nodes = {
            edge =
              { pkgs, ... }:
              {
                imports = [
                  self.nixosModules.caddy
                  self.nixosModules.primaryMirror
                ];

                virtualisation = {
                  graphics = false;
                  vlans = [ 1 ];
                };

                networking.interfaces.eth1.ipv4.addresses = [
                  {
                    address = "10.10.0.1";
                    prefixLength = 24;
                  }
                ];

                # Use unreachable ACME with self-signed certificates.
                security.acme = {
                  acceptTerms = true;
                  defaults = {
                    email = "test@example.com";
                    dnsProvider = "cloudflare";
                    environmentFile = pkgs.writeText "acme-env" "CF_DNS_API_TOKEN=stub";
                    server = "https://acme.invalid/dir";
                  };
                };

                caddy = {
                  extended = true;
                  openFirewall = true;
                  listenAddresses = [ "127.0.0.1" ];
                  defaultPort = 8443;
                };

                primaryMirror = {
                  enable = true;

                  # Keeps failover inside the test's bounded waits.
                  healthInterval = "2s";
                  mtlsNames = [ "shoko.asmussen.tech" ];
                  passthroughNames = [
                    "jellyfin.asmussen.tech"
                    "asmussen.tech"
                  ];
                };

                services.caddy.virtualHosts = {
                  # Binds :443, the layer4 listener's fallthrough site.
                  "covenantofearth.org:443" = {
                    listenAddresses = [ ];
                    extraConfig = ''respond "covenant-edge" 200'';
                  };

                  "jellyfin.asmussen.tech".extraConfig = "respond 503";
                  "asmussen.tech".extraConfig = ''respond "asmussen-edge" 200'';
                };
              };

            primary =
              { pkgs, ... }:
              {
                imports = [
                  self.nixosModules.base
                  self.nixosModules.caddy
                  self.nixosModules.primaryBusy
                  gamemodeStub
                  testUser
                ];

                virtualisation = {
                  graphics = false;
                  vlans = [ 1 ];
                };

                networking = {
                  nftables.enable = true;

                  interfaces.eth1.ipv4.addresses = [
                    {
                      address = "10.10.0.2";
                      prefixLength = 24;
                    }
                  ];

                  hosts."127.0.0.1" = [ "shoko.asmussen.tech" ];

                  # The module's rules match wg0, which this VM does not have.
                  firewall.extraInputRules = ''
                    iifname "eth1" ip saddr 10.10.0.1 tcp dport 443 accept
                    iifname "eth1" ip saddr { 10.10.0.1, 10.10.0.3 } tcp dport 8443 accept
                    iifname "eth1" ip saddr 10.10.0.1 tcp dport 9444 accept
                  '';
                };

                # Use unreachable ACME with self-signed certificates.
                security.acme = {
                  acceptTerms = true;
                  defaults = {
                    email = "test@example.com";
                    dnsProvider = "cloudflare";
                    environmentFile = pkgs.writeText "acme-env" "CF_DNS_API_TOKEN=stub";
                    server = "https://acme.invalid/dir";
                  };
                };

                preferences.user.authorizedKeyFiles = [ ];

                caddy = {
                  extended = true;
                  listenAddresses = [ "10.10.0.2" ];
                  servers."10.10.0.2:443" = ''
                    listener_wrappers {
                      proxy_protocol {
                        allow 10.10.0.1/32
                      }

                      tls
                    }
                  '';
                };

                primaryBusy.enable = true;

                services.caddy.virtualHosts = {
                  "jellyfin.asmussen.tech" = {
                    extraConfig = "reverse_proxy localhost:8096";
                  };

                  "asmussen.tech" = {
                    extraConfig = "reverse_proxy localhost:8096";
                  };

                  # Only port 8443 requires a client certificate.
                  "shoko.asmussen.tech:8443" = {
                    clientCA = "${mtlsCerts}/ca.crt";
                    extraConfig = "reverse_proxy localhost:8096";
                  };

                  "shoko.asmussen.tech" = {
                    listenAddresses = [
                      "127.0.0.1"
                      "::1"
                    ];
                    extraConfig = "reverse_proxy localhost:8096";
                  };
                };

                systemd.services.header-echo = {
                  description = "Echoes request headers for the proxy assertions";
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig.ExecStart = headerEcho;
                };

                environment.systemPackages = [ pkgs.curl ];
              };

            client =
              { pkgs, ... }:
              {
                virtualisation = {
                  graphics = false;
                  vlans = [ 1 ];
                };

                networking = {
                  interfaces.eth1.ipv4.addresses = [
                    {
                      address = "10.10.0.3";
                      prefixLength = 24;
                    }
                  ];

                  hosts = {
                    "10.10.0.1" = [
                      "jellyfin.asmussen.tech"
                      "asmussen.tech"
                      "covenantofearth.org"
                    ];

                    "10.10.0.2" = [ "shoko.asmussen.tech" ];
                  };
                };

                environment = {
                  systemPackages = [ pkgs.curl ];

                  # The certificate must exist inside the VM image.
                  etc = {
                    "mtls-client.crt".source = "${mtlsCerts}/client.crt";
                    "mtls-client.key".source = "${mtlsCerts}/client.key";
                  };
                };
              };
          };

          testScript = ''
            import datetime as dt

            start_all()

            edge.wait_for_unit("caddy.service")
            primary.wait_for_unit("caddy.service")
            primary.wait_for_unit("primary-available.socket")
            primary.wait_for_unit("header-echo.service")

            # Passthrough preserves the client address.
            client.succeed(
                "curl -k https://jellyfin.asmussen.tech/"
                " | grep -q 'X-Forwarded-For: 10.10.0.3'"
            )

            # Covenant terminates on the edge.
            client.succeed(
                "curl -k https://covenantofearth.org/ | grep -q covenant-edge"
            )

            # The client-certificate listener refuses bare clients, directly and via the edge.
            client.fail(
                "curl -k --max-time 10 https://shoko.asmussen.tech:8443/"
            )
            client.succeed(
                "curl -k --max-time 10 --cert /etc/mtls-client.crt --key /etc/mtls-client.key"
                " -o /dev/null -w '%{http_code}' https://shoko.asmussen.tech:8443/"
                " | grep -q 200"
            )
            client.fail(
                "curl -k --max-time 10 --resolve shoko.asmussen.tech:443:10.10.0.1"
                " https://shoko.asmussen.tech/"
            )
            client.succeed(
                "curl -k --max-time 10 --cert /etc/mtls-client.crt --key /etc/mtls-client.key"
                " --resolve shoko.asmussen.tech:443:10.10.0.1"
                " -o /dev/null -w '%{http_code}' https://shoko.asmussen.tech/ | grep -q 200"
            )

            # Loopback on the primary bypasses the client-certificate requirement.
            primary.succeed(
                "curl -k https://shoko.asmussen.tech/ | grep -q 'X-Forwarded-For: 127.0.0.1'"
            )

            # The mirror fails over to its own sites while the primary is unavailable.
            primary.succeed("systemctl stop primary-busy-sync.timer")
            primary.succeed("systemctl stop primary-available.socket")
            client.wait_until_succeeds(
                "curl -k -o /dev/null -w '%{http_code}' https://jellyfin.asmussen.tech/"
                " | grep -q 503",
                timeout=dt.timedelta(seconds=15),
            )
            client.wait_until_succeeds(
                "curl -k https://asmussen.tech/ | grep -q asmussen-edge",
                timeout=dt.timedelta(seconds=15),
            )

            # The primary takes over once its availability port answers again.
            primary.succeed("systemctl start primary-available.socket")
            client.wait_until_succeeds(
                "curl -k https://jellyfin.asmussen.tech/"
                " | grep -q 'X-Forwarded-For: 10.10.0.3'",
                timeout=dt.timedelta(seconds=15),
            )
            primary.succeed("systemctl start primary-busy-sync.timer")

            # Only the mirror may reach the PROXY listener.
            client.fail(
                "curl -k --connect-timeout 3 --resolve jellyfin.asmussen.tech:443:10.10.0.2"
                " https://jellyfin.asmussen.tech/"
            )
          '';
        };
      };
    };
}
