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
          rev = "d347e703908d0406b7a7ef80e3a0e594d86b2215";
        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "dsh";
          version = "0.1.3-alpha.1";

          src = pkgs.fetchFromGitHub {
            inherit rev;

            owner = "deepseek-ai";
            repo = "deepseek-harness";
            hash = "sha256-7gje0bGlfRbo6qEubnKt3z8a6UjDGNW90g7phGU+s6g=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            inherit pnpm;
            fetcherVersion = 4;
            hash = "sha256-IoX7qY6lXVJtYDljhSJF157JwZR72QZ1YX8Jpts7awk=";
          };

          # Trust the mTLS proxy and persist settings host-side.
          patches = [ ./settings-host-persistence.patch ];

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
