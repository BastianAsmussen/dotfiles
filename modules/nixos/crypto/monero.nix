{
  lib,
  config,
  pkgs,
  ...
}: {
  options.monero = with lib; {
    enable = mkEnableOption "Enables Monero application.";

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
    (lib.mkIf config.monero.enable {
      environment.systemPackages = [
        pkgs.monero-gui
      ];
    })

    (lib.mkIf config.monero.mining.enable {
      assertions = [
        {
          assertion = config.monero.mining.maxUsagePercentage >= 1 && config.monero.mining.maxUsagePercentage <= 100;
          message = "`maxUsagePercentage` must be between 1 and 100!";
        }
      ];

      services.xmrig = with config.monero.mining; {
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
