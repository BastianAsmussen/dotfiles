{
  flake.nixosModules.monero = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf mkMerge types mkOption;

    cfg = config.monero;
  in {
    options.monero.mining = mkOption {
      default = {};
      type = types.submodule {
        options = {
          enable = lib.mkEnableOption "Enables XMRig service.";

          pool = mkOption {
            default = "pool.supportxmr.com:443";
            description = "The URL of the Monero pool to use.";
            type = types.str;
          };

          wallet = mkOption {
            description = "The wallet address to use.";
            type = types.str;
          };

          maxUsagePercentage = mkOption {
            default = 100;
            description = "This option is just a hint for automatic configuration and can't precisely define CPU usage.";
            type = types.int;
          };
        };
      };
    };

    config = mkMerge [
      {
        environment.systemPackages = [pkgs.monero-gui];
      }
      (mkIf cfg.mining.enable {
        assertions = [
          {
            assertion = cfg.mining.maxUsagePercentage >= 1 && cfg.mining.maxUsagePercentage <= 100;
            message = "`maxUsagePercentage` must be between 1 and 100!";
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
