{
  flake.homeModules.bash =
    { lib, ... }:
    {
      programs.bash = {
        enable = true;

        # bash-completion wants `progcomp`, which the readline-less build lacks.
        bashrcExtra =
          # sh
          ''
            type -t bind >/dev/null || BASH_COMPLETION_VERSINFO=skip
          '';

        # Devshell bash lacks `readline`,
        # so the `\[ \]` oh-my-posh emits print literally.
        initExtra =
          lib.mkAfter
            # sh
            ''
              if ! type -t bind >/dev/null; then
                unset PROMPT_COMMAND
                PS1='\n\033[1;32m[\u@\h:\w]\$\033[0m '
              fi
            '';
      };
    };
}
