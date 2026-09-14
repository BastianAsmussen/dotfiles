{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      src = pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "15581d14007fd01fb3f132016741962f34936ca2";
        hash = "sha256-GuCK3oy0DsMOQq7gHjIY/aeaukJcTvelfg+tp7R7Du4=";
      };

      # keeps cavemanBin()'s PATH lookup from hitting GitHub releases at
      # runtime.
      runtime = pkgs.buildGoModule {
        pname = "caveman-runtime";
        version = "1.3.3";

        inherit src;

        subPackages = [
          "proxy/cmd/caveman-proxy"
          "engine/cmd/caveman-engine"
          "mcp/cmd/caveman-mcp"
          "mem/cmd/cavemem"
          "browse/cmd/caveman-browse"
          "shrink/cmd/caveman-shrink"
        ];

        vendorHash = "sha256-Z7BoRlBf+MalIJHza081YXxZETBUO3N+IRIKSqHFQnY=";
      };

      cli = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "caveman-cli";
        version = "1.3.3";

        inherit src;

        nativeBuildInputs = with pkgs; [
          nodejs
          pnpm_10
          pnpmConfigHook
        ];

        pnpmWorkspaces = [ "@caveman-ai/cli" ];

        # `pnpm --filter` only needs this package's own graph.
        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (finalAttrs)
            pname
            version
            src
            pnpmWorkspaces
            ;

          pnpm = pkgs.pnpm_10;
          fetcherVersion = 4;
          hash = "sha256-JelS/xyW1v4XI972xH9x+JeZXJ7WY2qXVj90z1xT4Dc=";
        };

        buildPhase = ''
          runHook preBuild
          pnpm --filter @caveman-ai/cli run build
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/caveman-cli
          cp -r packages/cli/dist $out/lib/caveman-cli/dist
          patchShebangs $out/lib/caveman-cli/dist/index.js

          mkdir -p $out/bin
          ln -s $out/lib/caveman-cli/dist/index.js $out/bin/caveman
          ln -s $out/lib/caveman-cli/dist/index.js $out/bin/cave

          runHook postInstall
        '';

        meta = {
          description = "Caveman CLI, wraps coding agents with local context compression (`caveman claude` for Claude Code)";
          homepage = "https://getcaveman.dev";
          license = lib.licenses.mit;
          mainProgram = "caveman";
          maintainers = [ lib.maintainers.BastianAsmussen ];
        };
      });
    in
    {
      packages.caveman-cli = pkgs.symlinkJoin {
        name = "caveman-cli-${cli.version}";
        paths = [
          cli
          runtime
        ];

        inherit (cli) meta;
      };
    };
}
