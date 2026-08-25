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

          # Pinned upstream release. master == this tag at time of writing; bump
          # rev + both hashes together on upgrade (dev preview: expect breakage).
          rev = "b150a551b8d465e31e418e1b2eaf5e79bbb7d28e";
        in
        pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "dsh";
          version = "0.1.1-rc.2";

          src = pkgs.fetchFromGitHub {
            inherit rev;

            owner = "deepseek-ai";
            repo = "deepseek-harness";
            hash = "sha256-rrjXoyccTxKIbZ00Z4Vy7EA9tGZ15WUqLBFnZSgw1YE=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (finalAttrs) pname version src;
            inherit pnpm;
            fetcherVersion = 4;
            hash = "sha256-+PsdK9u3ZKv4XtSc8tBKKP48J/95/CGTMIUf8Q8dbok=";
          };

          # Settings, themes, and provider config are client-gated to loopback
          # origins; behind the mTLS proxy every origin is remote by that
          # definition. Trust the proxy fence instead and persist host-side.
          patches = [ ./settings-host-persistence.patch ];

          nativeBuildInputs = [
            nodejs
            pnpm
            pkgs.pnpmConfigHook
            pkgs.node-gyp
            pkgs.python3
            pkgs.makeWrapper
          ];

          # The client build embeds the source commit; without this it shells
          # out to `git rev-parse HEAD`, which fails in the sandbox. Leave
          # esbuild to resolve its own bundled @esbuild/linux-x64 (a static Go
          # binary in the pnpm store); overriding ESBUILD_BINARY_PATH would
          # force a version mismatch against the pinned esbuild host.
          env = {
            CI = "true";
            DSH_CLIENT_COMMIT_HASH = builtins.substring 0 7 rev;
          };

          buildPhase = ''
            runHook preBuild

            export HOME=$(mktemp -d)

            # pnpmConfigHook installs with --ignore-scripts, so the one native
            # addon we keep (node-pty; the rest ship prebuilds) is left uncompiled.
            # scripts/prebuild.js would fetch a prebuilt binary from the network,
            # so drive node-gyp directly against the nixpkgs node headers.
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

            # --expose-internals is load-bearing: vendor/loader hooks Node's
            # internal ESM loader to resolve @deepseek-ai/* workspace plugins
            # with an explicit parentURL into $DSH_HOME/profiles/node_modules.
            # Without it the loader degrades to a plain import() anchored at
            # its own file and every plugin fails with ERR_MODULE_NOT_FOUND.
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
