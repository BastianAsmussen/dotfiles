{
  flake.homeModules.goxlrUtility =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      jsonFormat = pkgs.formats.json { };

      cfg = config.services.goxlr-utility;
      dataDir = "${config.xdg.dataHome}/goxlr-utility";

      inherit (lib)
        isList
        filterAttrs
        concatStrings
        mapAttrsToList
        mkOption
        literalExpression
        mkIf
        optionalString
        ;
      inherit (lib.types)
        str
        int
        attrsOf
        nullOr
        path
        ;

      # Mirror profile XML as attrsets; stringify floats to avoid lossy Nix
      # printing.
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
              lib.mapAttrsToList (name: value: " ${name}=\"${lib.escapeXML (toString value)}\"") attrs
            );

          renderElement =
            indent: name: value:
            let
              attrs = filterAttrs (_: v: !isElement v) value;
              children = filterAttrs (_: isElement) value;

              renderChild =
                childName: v:
                if isList v then
                  concatStrings (map (renderElement "${indent}\t" childName) v)
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

      # Pack profile.xml and scribble images as a .goxlr ZIP archive.
      mkProfile =
        name: value:
        pkgs.runCommand "${name}.goxlr" { nativeBuildInputs = [ pkgs.zip ]; } ''
          mkdir build && cd build
          cp ${pkgs.writeText "${name}-profile.xml" (toXml "ValueTreeRoot" value.profile)} profile.xml
          ${concatStrings (
            mapAttrsToList (fileName: src: ''
              cp ${src} ${lib.escapeShellArg fileName}
            '') value.files
          )}

          find . -type f | sort | zip --quiet -X "$out" -@
        '';

      profilesDir = pkgs.linkFarm "goxlr-profiles" (
        mapAttrsToList (name: value: {
          name = "${name}.goxlr";
          path = mkProfile name value;
        }) cfg.profiles
      );

      micProfilesDir = pkgs.linkFarm "goxlr-mic-profiles" (
        mapAttrsToList (name: tree: {
          name = "${name}.goxlrMicProfile";
          path = pkgs.writeText "${name}.goxlrMicProfile" (toXml "MicProfileTree" tree);
        }) cfg.micProfiles
      );

      iconsDir = pkgs.linkFarm "goxlr-icons" (
        mapAttrsToList (name: path: { inherit name path; }) cfg.icons
      );

      xml2json = pkgs.writeScriptBin "goxlr-xml2json" ''
        #!${lib.getExe pkgs.python3}

        ${builtins.readFile ./xml2json.py}
      '';

      # Export daemon profiles as declarative JSON sources.
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
            rm "$tmp/profile.xml"

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
          type = attrsOf (
            lib.types.submodule {
              options = {
                profile = mkOption {
                  type = xmlTreeType;
                  description = "Profile tree rendered to profile.xml inside the archive.";
                };

                files = mkOption {
                  type = attrsOf path;
                  default = { };
                  description = "Extra archive members, such as the fader scribble images.";
                };
              };
            }
          );
          default = { };
          example = literalExpression ''
            {
              Default = {
                profile = lib.importJSON ./profiles/Default/profile.json;
                files."scribble1.png" = ./profiles/Default/scribble1.png;
              };
            }
          '';
          description = "Profiles to install, by name, packed into .goxlr archives at build time.";
        };

        micProfiles = mkOption {
          type = attrsOf xmlTreeType;
          default = { };
          example = literalExpression "{ DEFAULT = lib.importJSON ./mic-profiles/DEFAULT.json; }";
          description = "Mic profiles to install, by name, rendered to XML at build time.";
        };

        icons = mkOption {
          type = attrsOf path;
          default = { };
          example = literalExpression ''{ "game-controller.png" = ./icons/game-controller.png; }'';
          description = ''
            Icons to install into the icons directory, by file name, for use in
            scribble iconFile attributes. Installed alongside the icons the
            daemon ships; declared names overwrite existing ones.
          '';
        };

        settings = mkOption {
          inherit (jsonFormat) type;

          default = { };
          example = literalExpression ''
            {
              firmware_source = "Live";
              devices."S000000000000".profile = "Default";
            }
          '';
          description = "Contents of settings.json.";
        };

        export.directory = mkOption {
          type = nullOr str;
          default = null;
          example = "/home/user/dotfiles/modules/homeManagerModules/goxlr";
          description = ''
            Directory the goxlr-export tool writes daemon-saved profiles back
            into as JSON sources, laid out the way the profiles and micProfiles
            options expect. If null, the tool is not installed.
          '';
        };
      };

      config = mkIf cfg.enable {
        home.packages = lib.optional (cfg.export.directory != null) goxlr-export;

        # Save Profile needs writable copies; rebuilds restore declared state.
        home.activation.goxlrProfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          if [ -L "${dataDir}/profiles" ]; then run rm "${dataDir}/profiles"; fi
          if [ -L "${dataDir}/mic-profiles" ]; then run rm "${dataDir}/mic-profiles"; fi

          run mkdir -p "${dataDir}/profiles" "${dataDir}/mic-profiles" "${dataDir}/icons"
          ${optionalString (cfg.profiles != { }) ''
            run install -m 644 ${profilesDir}/*.goxlr "${dataDir}/profiles/"
          ''}
          ${optionalString (cfg.micProfiles != { }) ''
            run install -m 644 ${micProfilesDir}/*.goxlrMicProfile "${dataDir}/mic-profiles/"
          ''}
          ${optionalString (cfg.icons != { }) ''
            run install -m 644 ${iconsDir}/* "${dataDir}/icons/"
          ''}
        '';

        # The daemon replaces this symlink at runtime; force restores it on
        # rebuild.
        xdg.configFile."goxlr-utility/settings.json" = mkIf (cfg.settings != { }) {
          force = true;
          source = jsonFormat.generate "goxlr-settings.json" cfg.settings;
        };
      };
    };
}
