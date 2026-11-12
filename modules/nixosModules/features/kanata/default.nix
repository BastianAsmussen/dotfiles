{
  flake.nixosModules.kanata =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (lib) mkOption types;

      cfg = config.kanata;
      r = cfg.tappingResolution;

      # Sunaku's Glorious Engrammer timings, derived from one resolution.
      timings = {
        pinky-hold = r + 110;
        ringy-hold = r + 90;
        middy-hold = r + 60;
        index-hold = r + 20;
        homey-idle = r;
        index-idle = r - 50;
        homey-repeat = r + 150;
        thumb-hold = r + 50;
        thumb-repeat = r + 150;
        space-hold = r + 20;
        space-repeat = r;
        sticky-hold = r + 50;
      };
    in
    {
      options.kanata = {
        tappingResolution = mkOption {
          type = types.ints.between 50 1000;
          default = 200;
          description = ''
            Base tap-hold timing (milliseconds) from which the per-finger hold,
            typing-streak and repeat timings are derived. The default matches
            the Glove80's `DIFFICULTY_LEVEL 4`.
          '';
        };

        devices = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
          description = "Keyboard devices kanata grabs; empty grabs every keyboard.";
        };
      };

      config.services.kanata = {
        enable = true;
        keyboards.default = {
          inherit (cfg) devices;
          extraDefCfg = ''
            process-unmapped-keys yes
            concurrent-tap-hold yes
          '';
          config = ''
            (defvar
            ${lib.concatStrings (lib.mapAttrsToList (name: ms: "  ${name} ${toString ms}\n") timings)})

            ${builtins.readFile ./glorious-engrammer.kbd}
          '';
        };
      };
    };
}
