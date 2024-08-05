{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.monero;
in {
  options.monero = with lib; {
    gui.enable = mkEnableOption "Enables Monero application.";

    mining = {
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

  config = lib.mkMerge [
    (lib.mkIf cfg.gui.enable {
      environment.systemPackages = with pkgs; [
        monero-gui
      ];
    })

    (lib.mkIf cfg.mining.enable {
      assertions = [
        {
          assertion = cfg.mining.maxUsagePercentage >= 1 && cfg.mining.maxUsagePercentage <= 100;
          message = "`maxUsagePercentage` must be between 1 and 100!";
        }
      ];

      services.xmrig = with cfg.mining; {
        enable = true;

        settings = {
          autosave = true;
          opencl = false;
          cuda = false;
          cpu = {
            enabled = true;
            max-threads-hint = maxUsagePercentage;
          };

          pools = [
            {
              url = pool;
              user = wallet;
              keepalive = true;
              tls = true;
            }
          ];
        };
      };
    })
  ];
}
