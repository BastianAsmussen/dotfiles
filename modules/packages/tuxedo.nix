{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.tuxedo = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "tuxedo";
        version = "2026.7.1";
        __structuredAttrs = true;

        src = pkgs.fetchFromGitHub {
          owner = "webstonehq";
          repo = "tuxedo";
          tag = "v${finalAttrs.version}";
          hash = "sha256-4tkKjFQN6giCBVOs8K/EjGFAG73CWtPGC4e8YPpxFEs=";
        };

        cargoHash = "sha256-jkrxG7KyAUStyZonAZbgRPkEnElpzYrCDdvCkb2cW2A=";

        preCheck = ''
          export HOME="$TMPDIR/home"
          export XDG_CONFIG_HOME="$TMPDIR/config"
          export XDG_CACHE_HOME="$TMPDIR/cache"
          export XDG_STATE_HOME="$TMPDIR/state"
          mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
        '';

        checkFlags = [ "--skip=insert_dialog_after_nl_parse" ];

        meta = {
          description = "A fast, keyboard-driven terminal UI for todo.txt";
          homepage = "https://github.com/webstonehq/tuxedo";
          changelog = "https://github.com/webstonehq/tuxedo/releases/tag/${finalAttrs.src.tag}";
          license = lib.licenses.mit;
          maintainers = with lib.maintainers; [
            iogamaster
            BastianAsmussen
          ];

          mainProgram = "tuxedo";
        };
      });
    };
}
