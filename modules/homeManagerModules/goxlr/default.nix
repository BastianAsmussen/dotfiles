{ self, ... }:
{
  flake.homeModules.goxlr =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) filterAttrs mapAttrs importJSON;
      inherit (builtins) readDir;
    in
    {
      imports = [ self.homeModules.goxlrUtility ];

      services.goxlr-utility = {
        enable = true;

        # Directories under profiles/ is a profile: profile.json is the XML
        # tree, all other files join the archive.
        # New profiles written by goxlr-export are picked up automatically.
        profiles =
          let
            profileDirs = filterAttrs (_: type: type == "directory") (readDir ./profiles);
          in
          mapAttrs (
            name: _:
            let
              dir = ./profiles + "/${name}";
            in
            {
              profile = importJSON (dir + "/profile.json");
              files = mapAttrs (fileName: _: dir + "/${fileName}") (
                filterAttrs (fileName: type: type == "regular" && fileName != "profile.json") (readDir dir)
              );
            }
          ) profileDirs;

        micProfiles = lib.mapAttrs' (
          fileName: _:
          lib.nameValuePair (lib.removeSuffix ".json" fileName) (importJSON (./mic-profiles + "/${fileName}"))
        ) (readDir ./mic-profiles);

        icons = lib.mapAttrs (fileName: _: ./icons + "/${fileName}") (readDir ./icons);
        export.directory = "${config.home.homeDirectory}/dotfiles/modules/homeManagerModules/goxlr";
        settings = {
          show_tray_icon = true;
          selected_locale = null;
          tts_enabled = false;
          allow_network_access = false;
          macos_handle_aggregates = true;
          profile_directory = null;
          mic_profile_directory = null;
          samples_directory = null;
          presets_directory = null;
          icons_directory = null;
          logs_directory = null;
          backup_directory = null;
          log_level = "Debug";
          open_ui_on_launch = false;
          activate = null;
          firmware_source = "Live";
          devices."S220105246CQK" = {
            profile = "Default";
            mic_profile = "DEFAULT";
            hold_delay = 500;
            sampler_pre_buffer = null;
            chat_mute_mutes_mic_to_chat = true;
            lock_faders = false;
            enable_monitor_with_fx = false;
            sampler_reset_on_clear = true;
            sampler_fade_duration = 500;
            vod_mode = "Routable";
            shutdown_commands = [ { LoadProfileColours = "Sleep"; } ];
            sleep_commands = [ ];
            wake_commands = [ ];
          };

          sample_gain = { };
        };
      };
    };
}
