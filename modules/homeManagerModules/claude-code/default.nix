{
  flake.homeModules.claudeCode =
    {
      config,
      osConfig ? null,
      lib,
      ...
    }:
    let
      # Present only on hosts that import the preservation module (epsilon).
      persistence = if osConfig == null then null else osConfig.persistence or null;
      persistEnabled = persistence != null && persistence.enable;

      home = config.home.homeDirectory;

      # Persist Claude credentials and session state through the userdata tree.
      persistBase = "${persistence.persistPath}/userdata${home}";

      claudeDir = "${home}/.claude";
      claudeJson = "${home}/.claude.json";
      persistDir = "${persistBase}/.claude";
      persistJson = "${persistBase}/.claude.json";
    in
    {
      programs.claude-code = {
        enable = true;

        # Manage global context in-repo; keep runtime edits in per-project
        # files.
        context = ./CLAUDE.md;
      };

      # Create persistence links before home-manager links files; adopt existing
      # state once.
      home.activation.claudeCodePersist = lib.mkIf persistEnabled (
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          run mkdir -p "${persistDir}"
          run chmod 700 "${persistDir}"

          if [ -e "${claudeDir}" ] && [ ! -L "${claudeDir}" ]; then
            run cp -a "${claudeDir}/." "${persistDir}/"
            run rm -rf "${claudeDir}"
          fi
          run ln -sfn "${persistDir}" "${claudeDir}"

          if [ -e "${claudeJson}" ] && [ ! -L "${claudeJson}" ]; then
            run mv "${claudeJson}" "${persistJson}"
          fi
          [ -e "${persistJson}" ] || run touch "${persistJson}"
          run ln -sfn "${persistJson}" "${claudeJson}"
        ''
      );
    };
}
