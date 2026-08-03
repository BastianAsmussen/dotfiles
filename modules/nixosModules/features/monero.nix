{
  flake.nixosModules.monero =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        escapeShellArg
        escapeShellArgs
        getExe'
        mkEnableOption
        mkIf
        mkMerge
        mkOption
        optional
        optionals
        types
        ;

      cfg = config.monero;

      inherit (cfg) node;

      monerod = getExe' pkgs.monero-cli "monerod";
      chattr = getExe' pkgs.e2fsprogs "chattr";

      monerodArgs = [
        "--data-dir"
        node.dataDir

        "--rpc-bind-ip"
        node.rpcAddress

        "--rpc-bind-port"
        (toString node.rpcPort)

        "--p2p-bind-ip"
        node.p2pAddress

        "--p2p-bind-port"
        (toString node.p2pPort)

        "--zmq-rpc-bind-ip"
        node.rpcAddress

        "--zmq-rpc-bind-port"
        (toString node.zmqPort)
      ]
      ++ optional node.prune "--prune-blockchain"
      ++ optionals (node.limitRateUp != null) [
        "--limit-rate-up"
        (toString node.limitRateUp)
      ]
      ++ optionals (node.limitRateDown != null) [
        "--limit-rate-down"
        (toString node.limitRateDown)
      ]
      ++ [
        "--non-interactive"
      ]
      ++ node.extraArgs;
    in
    {
      options.monero = {
        node = {
          enable = mkEnableOption "the Monero P2P node";

          user = mkOption {
            type = types.str;
            default = "monero";
            description = "System user under which monerod runs.";
          };

          group = mkOption {
            type = types.str;
            default = "monero";
            description = "Primary group under which monerod runs.";
          };

          uid = mkOption {
            type = types.ints.positive;
            example = 986;
            description = ''
              Stable UID assigned to the Monero system user.

              This must remain stable because the user owns the persistent
              blockchain data.
            '';
          };

          gid = mkOption {
            type = types.ints.positive;
            example = 983;
            description = ''
              Stable GID assigned to the Monero system group.
            '';
          };

          dataDir = mkOption {
            type = types.str;
            default = "/var/lib/monero";
            description = "Directory containing the Monero blockchain database.";
          };

          prune = mkOption {
            type = types.bool;
            default = false;
            description = "Run monerod in pruned mode.";
          };

          rpcAddress = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Address on which the monerod JSON-RPC server listens.";
          };

          rpcPort = mkOption {
            type = types.port;
            default = 18081;
            description = "Port on which the monerod JSON-RPC server listens.";
          };

          zmqPort = mkOption {
            type = types.port;
            default = 18082;
            description = "Port on which the monerod ZMQ interface listens.";
          };

          p2pAddress = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = "Address on which the monerod P2P server listens.";
          };

          p2pPort = mkOption {
            type = types.port;
            default = 18080;
            description = "Port on which the monerod P2P server listens.";
          };

          limitRateUp = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Upload limit in KiB/s, or null for unlimited.";
          };

          limitRateDown = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Download limit in KiB/s, or null for unlimited.";
          };

          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional command-line arguments passed to monerod.";
          };
        };

        gui = {
          enable = mkEnableOption "the Monero GUI wallet" // {
            default = true;
          };

          package = mkOption {
            type = types.package;
            default = pkgs.monero-gui;
            defaultText = lib.literalExpression "pkgs.monero-gui";
            description = "Package providing the Monero GUI wallet.";
          };
        };

        mining = {
          enable = mkEnableOption "the XMRig miner service";

          pool = mkOption {
            type = types.str;
            default = "pool.supportxmr.com:443";
            description = "Mining pool address.";
          };

          wallet = mkOption {
            type = types.str;
            description = "Wallet address receiving mining rewards.";
          };

          maxUsagePercentage = mkOption {
            type = types.ints.between 1 100;
            default = 100;
            description = "CPU usage hint forwarded to XMRig.";
          };
        };
      };

      config = mkMerge [
        (mkIf cfg.gui.enable {
          environment.systemPackages = [
            cfg.gui.package
          ];
        })

        (mkIf node.enable (mkMerge [
          {
            environment.systemPackages = [
              pkgs.monero-cli
            ];

            users = {
              users.${node.user} = {
                inherit (node) uid group;

                isSystemUser = true;
                home = node.dataDir;
              };

              groups.${node.group}.gid = node.gid;
            };

            systemd = {
              tmpfiles.rules = [
                "d ${node.dataDir} 0700 ${node.user} ${node.group} - -"
              ];

              services.monerod = {
                description = "Monero P2P node";

                wants = [
                  "network-online.target"
                ];

                after = [
                  "network-online.target"
                ];

                wantedBy = [
                  "multi-user.target"
                ];

                unitConfig.RequiresMountsFor = [
                  node.dataDir
                ];

                preStart = ''
                  # Disable Btrfs copy-on-write for newly created LMDB files.
                  ${chattr} +C ${escapeShellArg node.dataDir} \
                    2>/dev/null || true
                '';

                serviceConfig = {
                  Type = "simple";

                  User = node.user;
                  Group = node.group;
                  UMask = "0077";

                  ExecStart = "${monerod} ${escapeShellArgs monerodArgs}";

                  Restart = "on-failure";
                  RestartSec = 30;

                  LimitNOFILE = 65536;

                  PrivateDevices = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectSystem = "full";
                  NoNewPrivileges = true;
                };
              };
            };
          }

          # The state belongs to this feature. When the persistence module is
          # absent, this branch contributes no unknown options.
          (lib.optionalAttrs (options ? persistence) {
            persistence.directories = [
              {
                inherit (node) user group;

                directory = node.dataDir;
                mode = "0700";
              }
            ];
          })
        ]))

        (mkIf cfg.mining.enable {
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
