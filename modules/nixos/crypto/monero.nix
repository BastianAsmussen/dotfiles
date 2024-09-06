{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) types mkEnableOption mkOption mkMerge mkIf;

  cfg = config.monero;
in {
  options.monero = {
    gui.enable = mkEnableOption "Enables Monero application.";
    mining = mkOption {
      default = {enable = false;};
      type = types.submodule {
        options = {
          enable = mkEnableOption "Enables XMRig service.";
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
  };

  config = mkMerge [
    (mkIf cfg.gui.enable {
      environment.systemPackages = [
        pkgs.monero-gui
      ];
    })

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
            max-threads-hint = cfg.maxUsagePercentage;
          };

          pools = [
            {
              url = cfg.pool;
              user = cfg.wallet;
              keepalive = true;
              tls = true;
            }
          ];
        };
      };
    })
  ];
}
