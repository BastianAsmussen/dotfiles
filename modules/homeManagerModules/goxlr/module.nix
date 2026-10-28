{
  flake.homeModules.goxlrUtility =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        isList
        filterAttrs
        concatStrings
        mapAttrsToList
        concatMapStrings
        escapeShellArg
        mkOption
        literalExpression
        mkIf
        ;

      inherit (lib.types)
        str
        int
        attrsOf
        nullOr
        path
        ;

      inherit (pkgs) linkFarm writeText;

      jsonFormat = pkgs.formats.json { };
      xmlValueType =
        lib.types.oneOf [
          str
          int
          (attrsOf xmlValueType)
          (lib.types.listOf (attrsOf xmlValueType))
        ]
        // {
          description = "XML attribute value (string or int), element (attrset), or list of elements";
        };

      xmlTreeType = attrsOf xmlValueType;

      toXml =
        rootName: tree:
        let
          isElement = value: lib.isAttrs value || isList value;
          renderAttrs =
            attrs:
            concatStrings (
              mapAttrsToList (name: value: " ${name}=\"${lib.escapeXML (toString value)}\"") attrs
            );

          renderElement =
            indent: name: value:
            let
              attrs = filterAttrs (_: v: !isElement v) value;
              children = filterAttrs (_: isElement) value;

              renderChild =
                childName: v:
                if isList v then
                  concatMapStrings (renderElement "${indent}\t" childName) v
                else
                  renderElement "${indent}\t" childName v;
            in
            if children == { } then
              "${indent}<${name}${renderAttrs attrs}/>\n"
            else
              "${indent}<${name}${renderAttrs attrs}>\n"
              + concatStrings (mapAttrsToList renderChild children)
              + "${indent}</${name}>\n";
        in
        ''<?xml version="1.0" encoding="utf-8"?>'' + "\n" + renderElement "" rootName tree;

      # A .goxlr profile is just a ZIP archive of profile.xml plus the scribble
      # images, packed at build time.
      mkProfile =
        name: value:
        let
          # Packaged XML profile config.
          xmlProfile = writeText "${name}-profile.xml" (toXml "ValueTreeRoot" value.profile);
          profileFiles = value.files // {
            "profile.xml" = xmlProfile;
          };

          installConfigs = concatStrings (
            mapAttrsToList (
              fileName: src:
              # sh
              ''
                cp ${src} ${escapeShellArg fileName}
              '') profileFiles
          );
        in
        pkgs.runCommand "${name}.goxlr" { nativeBuildInputs = [ pkgs.zip ]; } ''
          mkdir build && cd build
          ${installConfigs}

          find . -type f | sort | zip --quiet -X "$out" -@
        '';

      cfg = config.services.goxlr-utility;

      dataDir = "${config.xdg.dataHome}/goxlr-utility";
      profilesDir = linkFarm "goxlr-profiles" (
        mapAttrsToList (name: value: {
          name = "${name}.goxlr";
          path = mkProfile name value;
        }) cfg.profiles
      );

      micProfilesDir = linkFarm "goxlr-mic-profiles" (
        mapAttrsToList (name: tree: {
          name = "${name}.goxlrMicProfile";
          path = writeText "${name}.goxlrMicProfile" (toXml "MicProfileTree" tree);
        }) cfg.micProfiles
      );

      iconsDir = linkFarm "goxlr-icons" (mapAttrsToList (name: path: { inherit name path; }) cfg.icons);

      xml2json = pkgs.writers.writePython3Bin "goxlr-xml2json" { } (builtins.readFile ./xml2json.py);

      # Converts profiles saved by the daemon back into JSON sources in the
      # repository to manage it declaratively.
      goxlr-export = pkgs.writeShellApplication {
        name = "goxlr-export";
        runtimeInputs = [
          pkgs.unzip
          xml2json
        ];

        text = ''
          shopt -s nullglob

          config_dir="''${GOXLR_CONFIG_DIR:-${cfg.export.directory}}"

          for archive in "${dataDir}"/profiles/*.goxlr; do
            name="$(basename "$archive" .goxlr)"
            dest="$config_dir/profiles/$name"
            tmp="$(mktemp -d)"

            unzip -o -q "$archive" -d "$tmp"
            mkdir -p "$dest"
            goxlr-xml2json "$tmp/profile.xml" > "$dest/profile.json"
            rm -f "$tmp/profile.xml"

            for extra in "$tmp"/*; do
              cp "$extra" "$dest/"
            done

            rm -rf "$tmp"

            echo "Exported profile: $name"
          done

          for mic_profile in "${dataDir}"/mic-profiles/*.goxlrMicProfile; do
            name="$(basename "$mic_profile" .goxlrMicProfile)"

            mkdir -p "$config_dir/mic-profiles"
            goxlr-xml2json "$mic_profile" > "$config_dir/mic-profiles/$name.json"

            echo "Exported mic profile: $name"
          done

          echo "Review with: git -C $config_dir diff"
        '';
      };
    in
    {
      options.services.goxlr-utility = {
        enable = lib.mkEnableOption "declarative GoXLR Utility configuration";
        profiles = mkOption {
          default = { };
          type = attrsOf (
            lib.types.submodule {
              options = {
                profile = mkOption {
                  type = xmlTreeType;
                  description = "Profile tree rendered to profile.xml inside the archive.";
                };

                files = mkOption {
                  default = { };
                  type = attrsOf path;
                  description = "Extra archive members, such as the fader scribble images.";
                };
              };
            }
          );

          description = "Profiles to install, by name.";
          example =
            literalExpression
              # nix
              ''
                {
                  Default = {
                    profile = lib.importJSON ./profiles/Default/profile.json;
                    files."scribble1.png" = ./profiles/Default/scribble1.png;
                  };
                }
              '';
        };

        micProfiles = mkOption {
          default = { };
          type = attrsOf xmlTreeType;
          description = "Mic profiles to install, by name, rendered to XML at build time.";
          example =
            literalExpression
              # nix
              "{ DEFAULT = lib.importJSON ./mic-profiles/DEFAULT.json; }";
        };

        icons = mkOption {
          default = { };
          type = attrsOf path;
          description = ''
            Icons to install into its config directory by file name. It is for
            use in scribble iconFile attributes. Installed alongside the icons
            the daemon ships. Declared names overwrite existing ones.
          '';

          example =
            literalExpression
              # nix
              ''{ "game-controller.png" = ./icons/game-controller.png; }'';
        };

        settings = mkOption {
          inherit (jsonFormat) type;

          description = "Contents of settings.json.";
          default = { };
          example =
            literalExpression
              # nix
              ''
                {
                  firmware_source = "Live";
                  devices."S000000000000".profile = "Default";
                }
              '';
        };

        export.directory = mkOption {
          default = null;
          type = nullOr str;
          description = ''
            Directory the goxlr-export tool writes the daemon's saved profiles
            back into as JSON sources. It is laid out to match what `profiles`
            and `micProfiles` options expect.
            The option being null means the tool isn't installed.
          '';

          example = "/home/user/dotfiles/modules/homeManagerModules/goxlr";
        };
      };

      config = mkIf cfg.enable {
        home = {
          packages = lib.optional (cfg.export.directory != null) goxlr-export;

          # The daemon requires write access to the profile directories for the
          # "Save Profile" button in the UI to work.
          activation.goxlrProfiles =
            let
              mkInstallCmd =
                p:
                # sh
                ''
                  run install -m 644 ${p.src} "${p.dest}"
                '';

              activeConfigs = builtins.filter (p: p.cfg != { }) [
                {
                  cfg = cfg.profiles;
                  src = "${profilesDir}/*.goxlr";
                  dest = "${dataDir}/profiles/";
                }
                {
                  cfg = cfg.micProfiles;
                  src = "${micProfilesDir}/*.goxlrMicProfile";
                  dest = "${dataDir}/mic-profiles/";
                }
                {
                  cfg = cfg.icons;
                  src = "${iconsDir}/*";
                  dest = "${dataDir}/icons/";
                }
              ];

              installConfigs = concatMapStrings mkInstallCmd activeConfigs;
            in
            lib.hm.dag.entryAfter [ "linkGeneration" ]
              # sh
              ''
                if [ -L "${dataDir}/profiles" ]; then run rm "${dataDir}/profiles"; fi
                if [ -L "${dataDir}/mic-profiles" ]; then run rm "${dataDir}/mic-profiles"; fi

                run mkdir -p "${dataDir}/profiles" "${dataDir}/mic-profiles" "${dataDir}/icons"

                ${installConfigs}
              '';
        };

        # The daemon rewrites this file at runtime.
        xdg.configFile."goxlr-utility/settings.json" = mkIf (cfg.settings != { }) {
          force = true;
          source = jsonFormat.generate "goxlr-settings.json" cfg.settings;
        };
      };
    };
}
