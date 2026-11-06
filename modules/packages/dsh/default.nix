{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        dsh =
          let
            inherit (builtins) substring;
            inherit (lib) getExe;

            src = inputs.deepseek-harness;
            date = src.lastModifiedDate;
            nodejsOfficial = pkgs.callPackage ./_node.nix { };

            toolchain = with pkgs; [
              nodejsOfficial
              pnpm_11
            ];

            runtimeInputs =
              toolchain
              ++ (with pkgs; [
                bashInteractive
                bubblewrap
                coreutils
                git
                procps
                xdg-utils
              ]);
          in
          pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "dsh";
            version = "0.2.2-rc.1-unstable-${substring 0 4 date}-${substring 4 2 date}-${substring 6 2 date}";

            inherit src;

            nativeBuildInputs =
              toolchain
              ++ (with pkgs; [
                pnpmConfigHook
                makeWrapper
                autoPatchelfHook
              ]);

            buildInputs = with pkgs; [
              stdenv.cc.cc.lib
              libx11
              libxcb
              libxi
              libxkbcommon
            ];

            # The musl prebuilts ship beside their glibc counterparts and never load here.
            autoPatchelfIgnoreMissingDeps = [
              "libc.musl-x86_64.so.1"
              "libtinfo.so.6"
            ];

            pnpmDeps = pkgs.fetchPnpmDeps {
              inherit (finalAttrs) pname version src;

              pnpm = pkgs.pnpm_11;
              fetcherVersion = 5;
              hash = "sha256-kl9uffd+lYQcMExH2aFKfTPDGt4Z8pphGEyPkhp1Q1E=";
            };

            env = {
              CI = "true";
              DSH_CLIENT_COMMIT_HASH = src.rev;
            };

            postPatch = ''
              substituteInPlace packages/terminal/terminal-bash/src/config.ts \
                --replace-fail "'/bin/bash'" "'${getExe pkgs.bashInteractive}'"
              substituteInPlace packages/subprocess/subprocess-local/src/process-inspector.ts \
                --replace-fail "'/bin/ps'" "'${lib.getExe' pkgs.procps "ps"}'"
            '';

            buildPhase = ''
              runHook preBuild
              pnpm exec tsx scripts/build.ts --scope artifacts --profile official
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib/dsh
              cp -r package.json node_modules apps packages vendor native $out/lib/dsh/

              # Links into workspace members and fixtures that aren't shipped.
              find $out/lib/dsh -xtype l -delete

              makeWrapper ${getExe nodejsOfficial} $out/bin/dsh \
                --add-flags $out/lib/dsh/apps/cli/lib/bin.js \
                --prefix PATH : ${lib.makeBinPath runtimeInputs}

              runHook postInstall
            '';

            meta = {
              description = "DeepSeek Harness, a pluggable agent harness with a web UI";
              homepage = "https://github.com/deepseek-ai/deepseek-harness";
              license = lib.licenses.mit;
              mainProgram = "dsh";
              maintainers = [ lib.maintainers.BastianAsmussen ];
              platforms = [ "x86_64-linux" ];
            };
          });
      };
    };
}
