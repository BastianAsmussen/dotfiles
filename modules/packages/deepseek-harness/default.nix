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

          rev = "00102833dfaee1da9f48a3a8eae9d34005a75218";
        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "dsh";
          version = "0.1.7-alpha.2";

          src = pkgs.fetchFromGitHub {
            inherit rev;

            owner = "deepseek-ai";
            repo = "deepseek-harness";
            hash = "sha256-Fgc2qYdmMghr6f1zqIjTSNETjJ1PtLhVCBoqrNhuJsA=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            inherit pnpm;

            fetcherVersion = 4;
            hash = "sha256-i5XoYAHernnWFi3iAMrTUPJ5CQB4yx8XeSaChMotGyI=";
          };

          patches = [
            ./settings-host-persistence.patch
            ./expose-internals-builtins.patch
          ];

          nativeBuildInputs = [
            nodejs
            pnpm
            pkgs.pnpmConfigHook
            pkgs.node-gyp
            pkgs.python3
            pkgs.makeWrapper
          ];

          # Unset, the build shells out to `git rev-parse HEAD`.
          env = {
            CI = "true";
            DSH_CLIENT_COMMIT_HASH = builtins.substring 0 7 rev;
          };

          buildPhase = ''
            runHook preBuild

            export HOME=$(mktemp -d)

            # pnpmConfigHook implies --ignore-scripts, and prebuild.js wants the network.
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

            # vendor/loader hooks Node's internal ESM loader for the plugins.
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
