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

      # Preservation wipes the tmpfs root on every boot, so everything the CLI
      # writes under ~/.claude (OAuth credentials, session state) and
      # ~/.claude.json must live on /persist. Home-manager cannot register
      # entries with the NixOS-side preservation module, so this feature owns
      # its own state by symlinking into the same userdata tree preservation
      # uses for the rest of the home directory.
      persistBase = "${persistence.persistPath}/userdata${home}";

      claudeDir = "${home}/.claude";
      claudeJson = "${home}/.claude.json";
      persistDir = "${persistBase}/.claude";
      persistJson = "${persistBase}/.claude.json";
    in
    {
      programs.claude-code = {
        enable = true;

        # Nix-managed global context, linked to ~/.claude/CLAUDE.md. Populate
        # the imported file in-repo; runtime edits belong in per-project
        # CLAUDE.md files instead.
        context = ./CLAUDE.md;
      };

      # Establish the persist symlinks before home-manager links its own files
      # (CLAUDE.md, settings.json, plugins) into ~/.claude, so those writes
      # land on /persist instead of the tmpfs that is erased at boot. Existing
      # real state from a pre-persistence layout is adopted once, then replaced.
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
