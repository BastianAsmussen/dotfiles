{ inputs, self, ... }:
{
  flake.wrapperModules.noctalia =
    {
      lib,
      wlib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib) mkOption types;
      inherit (self) theme;

      tomlFormat = pkgs.formats.toml { };
      jsonFormat = pkgs.formats.json { };

      configHome = pkgs.runCommand "noctalia-config" { } ''
        install -Dm644 ${tomlFormat.generate "config.toml" config.settings} $out/noctalia/config.toml
        ${lib.concatMapAttrsStringSep "\n" (
          name: palette:
          "install -Dm644 ${jsonFormat.generate "${name}.json" palette} $out/noctalia/palettes/${name}.json"
        ) config.palettes}

        HOME=$TMPDIR ${lib.getExe config.package} config validate $out/noctalia > log 2>&1 || true
        cat log
        if grep -qE '^(WARN|ERROR)' log; then
          exit 1
        fi
      '';
    in
    {
      imports = [ wlib.modules.default ];

      options = {
        settings = mkOption {
          inherit (tomlFormat) type;

          default = { };
          description = "Noctalia configuration, written to `noctalia/config.toml` in the config home.";
        };

        palettes = mkOption {
          type = types.attrsOf jsonFormat.type;
          default = { };
          description = "Custom palettes, written to `noctalia/palettes/<name>.json` in the config home.";
        };

        useIpLocation = mkOption {
          type = types.bool;
          default = false;
          description = "Use IP-based geolocation for weather instead of the static city name.";
        };

        idleEnabled = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable idle screen-off and lock timeouts.";
        };
      };

      config = {
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

        env.NOCTALIA_CONFIG_HOME = "${configHome}";
        passthru = { inherit configHome; };

        # Derive theme from system's active base16 colorscheme.
        palettes.Stylix.dark =
          let
            inherit (theme)
              base00
              base01
              base02
              base03
              base04
              base05
              base07
              base08
              base0A
              base0B
              base0C
              base0D
              base0E
              ;

            ansi = {
              red = base08;
              green = base0B;
              yellow = base0A;
              blue = base0D;
              magenta = base0E;
              cyan = base0C;
            };
          in
          {
            terminal = {
              background = base00;
              foreground = base05;
              cursor = base05;
              cursorText = base00;
              selectionBg = base02;
              selectionFg = base05;
              normal = ansi // {
                black = base00;
                white = base05;
              };

              bright = ansi // {
                black = base03;
                white = base07;
              };
            };

            mError = base08; # red
            mHover = base0C; # teal
            mOnError = base00; # base
            mOnHover = base00; # base
            mOnPrimary = base00; # base
            mOnSecondary = base00; # base
            mOnSurface = base05; # text
            mOnSurfaceVariant = base04; # subtext0
            mOnTertiary = base00; # base
            mOutline = base03; # overlay0
            mPrimary = base0D; # blue
            mSecondary = base05; # text
            mShadow = base00; # base
            mSurface = base00; # base
            mSurfaceVariant = base01; # surface0
            mTertiary = base0C; # teal
          };

        settings = {
          theme = {
            mode = "dark";
            source = "custom";
            custom_palette = "Stylix";
          };

          shell = {
            avatar_path = "${../../assets/icons/bastian.png}";
            clipboard_enabled = false;
            telemetry_enabled = false;
            shadow.direction = "down_right";
          };

          bar.main = {
            position = "left";
            capsule = false;
            start = [
              "control-center"
              "workspaces"
            ];

            end = [
              "notifications"
              "power_profile"
              "volume"
              "battery"
              "microphone"
              "keyboard_layout"
              "clock"
              "tray"
            ];
          };

          widget = {
            workspaces = {
              show_labels = false;
              hide_when_empty = true;
            };

            volume.show_label = false;
            microphone = {
              type = "volume";
              device = "input";
              show_label = false;
            };

            clock = {
              format = "{:%H:%M %a, %b %d}";
              vertical_format = "{:%H\n%M\n-\n%d\n%m}";
            };

            tray = {
              drawer = true;
              hide_passive = false;
            };
          };

          control_center = {
            shortcuts = map (type: { inherit type; }) [
              "wifi"
              "bluetooth"
              "notification"
              "power_profile"
            ];

            calendar.show_week_numbers = true;
          };

          wallpaper = {
            directory = "${../../assets/wallpapers}";
            default.path = "${../../assets/wallpapers/tokyo.png}";
            transition = [
              "fade"
              "disc"
              "wipe"
            ];
          };

          backdrop = {
            enabled = true;
            blur_intensity = 0.4;
            tint_intensity = 0.6;
          };

          lockscreen = {
            blur_intensity = 0.4;
            tint_intensity = 0.6;
          };

          idle.behavior = {
            screen-off = {
              timeout = 300;
              action = "screen_off";
              enabled = config.idleEnabled;
            };

            lock = {
              timeout = 330;
              action = "lock";
              enabled = config.idleEnabled;
            };
          };

          location =
            if config.useIpLocation then
              { auto_locate = true; }
            else
              { address = inputs.nix-secrets.user.city; };

          weather = {
            enabled = true;
            effects = true;
          };

          notification = {
            layer = "overlay";
            background_opacity = 1.0;
          };

          osd.position = "bottom_center";
        };
      };
    };

  perSystem =
    { pkgs, ... }:
    {
      packages.noctalia = inputs.wrapper-modules.lib.evalPackage [
        { inherit pkgs; }
        self.wrapperModules.noctalia
      ];
    };
}
