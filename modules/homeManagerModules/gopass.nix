{
  flake.homeModules.gopass =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # gopassbridge extension ID, kept in sync with `firefox.nix`.
      gopassBridgeId = "{eec37db0-22ad-4bf1-9068-5ae08df8c7e9}";

      goPassWrapper = pkgs.writeShellScript "gopass_wrapper.sh" ''
        # Export GPG_TTY only for a real TTY; otherwise use graphical pinentry.
        tty=$(tty 2>/dev/null) && export GPG_TTY="$tty"

        export GNUPGHOME="''${GNUPGHOME:-$HOME/.gnupg}"
        export PATH="${
          lib.makeBinPath (
            with pkgs;
            [
              gopass
              gnupg
            ]
          )
        }:$PATH"

        exec ${pkgs.gopass-jsonapi}/bin/gopass-jsonapi listen
      '';

      # Declarative replacement for the manifest written by `gopass-jsonapi configure`.
      nativeMessagingManifest = (pkgs.formats.json { }).generate "com.justwatch.gopass.json" {
        name = "com.justwatch.gopass";
        description = "Gopass wrapper to search and return passwords";
        path = "${goPassWrapper}";
        type = "stdio";
        allowed_extensions = [ gopassBridgeId ];
      };
    in
    {
      home = {
        packages = with pkgs; [
          gopass
          gopass-hibp
          gopass-jsonapi
        ];

        shellAliases.pass = "gopass";

        file.".mozilla/native-messaging-hosts/com.justwatch.gopass.json".source = nativeMessagingManifest;
      };

      xdg.configFile."gopass/config".source = (pkgs.formats.ini { }).generate "gopass-config" {
        mounts.path = "${config.home.homeDirectory}/.password-store";
        core.autosync = true;
      };

      persistence.directories = [
        # The encrypted store itself, and gopass's index beside it.
        ".password-store"
        ".local/share/gopass"
      ];
    };
}
