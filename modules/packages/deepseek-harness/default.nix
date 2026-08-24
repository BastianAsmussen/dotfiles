{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.deepseek-harness =
        let
          nodejs = pkgs.nodejs_22;
          pnpm = pkgs.pnpm_11;

          # Pinned release; update rev and both hashes together.
          rev = "b150a551b8d465e31e418e1b2eaf5e79bbb7d28e";
        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "dsh";
          version = "0.1.1-rc.2";

          src = pkgs.fetchFromGitHub {
            owner = "deepseek-ai";
            repo = "deepseek-harness";
            inherit rev;
            hash = "sha256-rrjXoyccTxKIbZ00Z4Vy7EA9tGZ15WUqLBFnZSgw1YE=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            inherit pnpm;
            fetcherVersion = 4;
            hash = "sha256-+PsdK9u3ZKv4XtSc8tBKKP48J/95/CGTMIUf8Q8dbok=";
          };

          nativeBuildInputs = [
            nodejs
            pnpm
            pkgs.pnpmConfigHook
            pkgs.node-gyp
            pkgs.python3
            pkgs.makeWrapper
          ];

          # Embed the source commit and use esbuild's pinned bundled binary.
          env = {
            CI = "true";
            DSH_CLIENT_COMMIT_HASH = builtins.substring 0 7 rev;
          };

          buildPhase = ''
            runHook preBuild

            export HOME=$(mktemp -d)

            # Build node-pty offline against nixpkgs headers; pnpm skips install
            # scripts.
            ptydir=$(find node_modules/.pnpm -type d -name node-pty -path '*/node_modules/node-pty' | head -n1)
            pushd "$ptydir"
            node-gyp rebuild --nodedir=${pkgs.srcOnly nodejs}
            popd

            pnpm run build

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/dsh
            cp -a . $out/lib/dsh/

            # Node's internal loader requires --expose-internals for workspace
            # plugin resolution.
            makeWrapper ${lib.getExe' nodejs "node"} $out/bin/dsh \
              --add-flags "--expose-internals $out/lib/dsh/apps/cli/lib/bin.js"

            runHook postInstall
          '';

          meta = {
            description = "DeepSeek Harness (dsh): plugin-based agent harness by DeepSeek AI.";
            homepage = "https://github.com/deepseek-ai/deepseek-harness";
            license = lib.licenses.mit;
            mainProgram = "dsh";
            platforms = lib.platforms.linux;
            maintainers = [ lib.maintainers.BastianAsmussen ];
          };
        });
    };
}
