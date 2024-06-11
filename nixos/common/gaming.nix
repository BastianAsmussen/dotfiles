{
  lib,
  config,
  pkgs,
  ...
}: {
  options.custom.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = let
    cfg = config.custom.gaming;
  in
    lib.mkIf cfg.enable {
      programs.steam = {
        enable = true;

	gamescopeSession.enable = true;
      };

      programs.gamemode.enable = true;

      environment = {
        sessionVariables = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
	};

	systemPackages = with pkgs; [
	  protonup
	  lutris
	  bottles
	  mangohud
	];
      };
    };
}

