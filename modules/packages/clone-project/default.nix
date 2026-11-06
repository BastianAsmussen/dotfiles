{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.clone-project = pkgs.writeTextFile {
        name = "clone-project";
        executable = true;
        destination = "/bin/clone-project";
        text = ''
          #!${pkgs.bashInteractive}/bin/bash
          export PATH="${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                fzf
                git
                tmux
              ]
            )
          }:$PATH"
          ${builtins.readFile ./clone-project.sh}
        '';
        checkPhase = ''
          runHook preCheck
          ${pkgs.stdenv.shellDryRun} "$target"
          ${lib.getExe pkgs.shellcheck-minimal} "$target"
          runHook postCheck
        '';

        meta = {
          description = "Clone a Git repository and open it as a tmux session.";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.BastianAsmussen ];
          platforms = lib.platforms.linux;
          mainProgram = "clone-project";
        };
      };
    };
}
