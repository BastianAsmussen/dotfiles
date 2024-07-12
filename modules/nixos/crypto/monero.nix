{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: {
  options.monero = {
    enable = lib.mkEnableOption "Enables XMRig mining.";

    pool = lib.mkOption {
      default = "pool.supportxmr.com:443";
      description = "The URL of the Monero pool to use.";
      type = lib.types.str;
    };

    wallet = lib.mkOption {
      description = "The wallet address to use.";
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.monero.enable {
    environment.systemPackages = [
      inputs.monero.legacyPackages.${pkgs.system}.monero-gui
    ];

    services.xmrig = {
      enable = true;

      settings = {
        autosave = true;
        cpu = true;
        opencl = false;
        cuda = false;

        pools = [
          {
            url = config.monero.pool;
            user = config.monero.wallet;
            keepalive = true;
            tls = true;
          }
        ];
      };
    };
  };
}
