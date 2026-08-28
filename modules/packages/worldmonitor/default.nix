{
  perSystem =
    { pkgs, lib, ... }:
    let
      nodejs = pkgs.nodejs_24;

      # Pinned commit; update rev and all four hashes together.
      rev = "f5b728b6da9880172819e99cee955d9b85765d47";
      version = "0-unstable-2026-08-23";

      src = pkgs.fetchFromGitHub {
        owner = "koala73";
        repo = "worldmonitor";
        inherit rev;
        hash = "sha256-2DVLoC9ZV5Dnqt28ukDFCVC6XY6jw5/cW5ecMWCVDmk=";
      };
    in
    {
      packages = {
        # Mirror the Docker builder's SPA and Node API sidecar build.
        worldmonitor =
          let
            # Use Docker's lockfile-exact npm ci; importNpmLock breaks its
            # overrides.
            proDeps = pkgs.fetchNpmDeps {
              name = "worldmonitor-pro-npm-deps";
              src = "${src}/pro-test";
              hash = "sha256-AkF7ULggc3MCvE0yygfP5vJRm8cX5YZAIwP1qZa+IAA=";
            };

            runtimeDeps = pkgs.fetchNpmDeps {
              name = "worldmonitor-runtime-npm-deps";
              src = "${src}/docker";
              postPatch = ''
                cp runtime-package.json package.json
                cp runtime-package-lock.json package-lock.json
              '';
              hash = "sha256-JvcZhRMUrIXN1fnolflhrt5lAGVFEFrJMpAVIbobIM8=";
            };
          in
          pkgs.buildNpmPackage {
            inherit version src nodejs;

            pname = "worldmonitor";

            # Strip entitlement and account gating without changing lockfiles or
            # FOD hashes.
            patches = [
              ./strip-pro-gating.patch
              ./fake-local-account.patch
            ];

            npmDeps = pkgs.fetchNpmDeps {
              inherit src;

              name = "worldmonitor-root-npm-deps";
              hash = "sha256-emND5urZsI9X8JsSvQDwZLXOPhDRheGaF8u0ZNlbSLE=";
            };

            # The image build never runs install scripts (no native deps needed).
            npmFlags = [ "--ignore-scripts" ];
            makeCacheWritable = true;
            dontNpmBuild = true;
            dontNpmPrune = true;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            # Runs after the npmConfigHook has done the root `npm ci`.
            buildPhase = ''
              runHook preBuild

              # Regenerate untracked inventory modules before handlers import
              # them.
              node scripts/generate-inventory-facts.mjs

              # Install pro dependencies offline and invoke bins through node to
              # bypass shebangs.
              cp -r --no-preserve=mode ${proDeps} pro-cache
              npm ci --prefix pro-test --offline --ignore-scripts --cache "$PWD/pro-cache"
              ( cd pro-test && node node_modules/vite/bin/vite.js build && node prerender.mjs )

              # Build corpus and frontend before emitting api JavaScript beside
              # its sources.
              node --import tsx scripts/build-crawlable-corpus.mjs
              node scripts/build-sitemap.mjs
              node node_modules/typescript/bin/tsc
              node node_modules/vite/bin/vite.js build

              # Only now compile the TS API handlers for the sidecar runtime.
              node docker/build-handlers.mjs

              # Assert /pro survived the public/ -> dist/ copy (upstream #6898).
              test -s dist/pro/index.html
              test -s dist/pro/welcome.html

              # Runtime node_modules for the sidecar: the smaller runtime closure.
              mkdir -p runtime-install
              cp docker/runtime-package.json runtime-install/package.json
              cp docker/runtime-package-lock.json runtime-install/package-lock.json
              cp -r --no-preserve=mode ${runtimeDeps} runtime-cache
              npm ci --prefix runtime-install --offline --omit=dev --omit=optional \
                --ignore-scripts --cache "$PWD/runtime-cache"

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              dir="$out/share/worldmonitor"
              mkdir -p "$dir"

              cp -r dist "$dir/dist"
              cp -r api "$dir/api"
              cp -r data "$dir/data"
              cp src-tauri/sidecar/local-api-server.mjs "$dir/local-api-server.mjs"
              cp -r runtime-install/node_modules "$dir/node_modules"

              # Serve the SPA with upstream nginx security headers and CSP.
              install -Dm644 docker/nginx-security-headers.conf \
                "$dir/nginx/security_headers.conf"
              install -Dm644 docker/nginx-embed-security-headers.conf \
                "$dir/nginx/embed_security_headers.conf"

              makeWrapper ${lib.getExe nodejs} "$out/bin/worldmonitor-sidecar" \
                --add-flags "$dir/local-api-server.mjs" \
                --set LOCAL_API_RESOURCE_DIR "$dir"

              runHook postInstall
            '';

            passthru = { inherit src; };

            meta = {
              description = "World Monitor situational-awareness dashboard (app + API sidecar)";
              homepage = "https://www.worldmonitor.app";
              license = lib.licenses.unfree; # source-available; see repo LICENSE
              mainProgram = "worldmonitor-sidecar";
              platforms = lib.platforms.linux;
              maintainers = [ lib.maintainers.BastianAsmussen ];
            };
          };

        # AIS relay sidecar (Node)
        worldmonitor-relay =
          let
            relayDeps = pkgs.fetchNpmDeps {
              name = "worldmonitor-relay-npm-deps";
              src = "${src}/scripts";
              hash = "sha256-Zfjy14AEAeLMmBS7fM1XHU287kp9iuVyNYFHS95RAok=";
            };
          in
          pkgs.stdenv.mkDerivation {
            inherit version src;

            pname = "worldmonitor-relay";
            nativeBuildInputs = [
              nodejs
              pkgs.makeWrapper
            ];

            # Match Dockerfile.relay by omitting optional native helpers and
            # scripts.
            buildPhase = ''
              runHook preBuild

              export HOME="$TMPDIR"

              cp -r --no-preserve=mode ${relayDeps} relay-cache
              npm ci --prefix scripts --offline --omit=dev --omit=optional \
                --ignore-scripts --cache "$PWD/relay-cache"

              # Generate the untracked inventory required by the relay at
              # startup.
              node scripts/generate-inventory-facts.mjs

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              dir="$out/share/worldmonitor-relay"
              mkdir -p "$dir"

              cp -r scripts "$dir/scripts"
              cp -r shared "$dir/shared"
              cp -r data "$dir/data"

              # Resolve relay resources from its script path, not the working
              # directory.
              makeWrapper ${lib.getExe nodejs} "$out/bin/worldmonitor-relay" \
                --add-flags "$dir/scripts/ais-relay.cjs"

              runHook postInstall
            '';

            meta = {
              description = "World Monitor AIS relay sidecar";
              homepage = "https://www.worldmonitor.app";
              license = lib.licenses.unfree;
              mainProgram = "worldmonitor-relay";
              platforms = lib.platforms.linux;
              maintainers = [ lib.maintainers.BastianAsmussen ];
            };
          };

        # Carry a pinned manifest for the Redis proxy's otherwise ad-hoc
        # dependency.
        worldmonitor-redis-rest =
          let
            modules = pkgs.importNpmLock.buildNodeModules {
              inherit nodejs;

              npmRoot = ./redis-rest;
            };
          in
          pkgs.stdenv.mkDerivation {
            inherit version src;

            pname = "worldmonitor-redis-rest";
            nativeBuildInputs = [
              nodejs
              pkgs.makeWrapper
            ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              dir="$out/share/worldmonitor-redis-rest"
              mkdir -p "$dir"

              cp ${src}/docker/redis-rest-proxy.mjs "$dir/redis-rest-proxy.mjs"
              cp -r ${modules}/node_modules "$dir/node_modules"

              makeWrapper ${lib.getExe nodejs} "$out/bin/worldmonitor-redis-rest" \
                --add-flags "$dir/redis-rest-proxy.mjs" \
                --set NODE_PATH "$dir/node_modules"

              runHook postInstall
            '';

            meta = {
              description = "Upstash-compatible Redis REST proxy for World Monitor";
              homepage = "https://www.worldmonitor.app";
              license = lib.licenses.unfree;
              mainProgram = "worldmonitor-redis-rest";
              platforms = lib.platforms.linux;
              maintainers = [ lib.maintainers.BastianAsmussen ];
            };
          };
      };
    };
}
