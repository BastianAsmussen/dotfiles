{
  flake.homeModules.goxlr =
    let
      dataDir = ".local/share/goxlr-utility";
      configDir = ".config/goxlr-utility";
    in
    {
      home.file = {
        "${dataDir}/profiles".source = ./goxlr-config/profiles;
        "${dataDir}/mic-profiles".source = ./goxlr-config/mic-profiles;
        "${configDir}/settings.json".text = builtins.toJSON {
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
