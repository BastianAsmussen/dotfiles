{
  perSystem =
    { pkgs, lib, ... }:
    let
      nodejs = pkgs.nodejs_24;

      # Pinned upstream commit. Bump rev + all four hashes (src + the three
      # npm closures) together on upgrade.
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
        # App: static SPA (dist) + Node API sidecar
        # Mirrors docker/../Dockerfile's builder stage (the compose image),
        # because `npm run build`, which drags in blog-site and other deps the
        # image omits.
        worldmonitor =
          let
            # pro-test and the runtime handler set are separate lockfiles the
            # Dockerfile installs with their own `npm ci`. npm ci is lockfile-exact,
            # so the repo's overrides (incl. self-referential `$ws`/`$undici`)
            # resolve exactly as under Docker, unlike importNpmLock, which rewrites
            # `resolved` to file: paths and then trips EOVERRIDE.
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

            # Self-hosted build, two chokepoints. The first neuters the client
            # entitlement snapshot so the "pro" paywall is gone. The second
            # covers what tier alone cannot reach: the account-scoped surfaces
            # gate on a Clerk sign-in this instance can never serve, so
            # getCurrentClerkUser() stands in a fixed local identity and every
            # `isSignedIn` downstream follows. Neither touches a lockfile, so
            # npmDeps and the shared src FOD hash are unaffected. Applied in
            # patchPhase, after fetchNpmDeps has read the pristine lockfile.
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

              # Untracked generated inventory modules, recreated before handlers
              # import them.
              node scripts/generate-inventory-facts.mjs

              # build:pro without the network: its `npm ci` is replaced by an
              # offline install from the prefetched pro-test closure. Bins are run
              # through `node` so unpatched `#!/usr/bin/env node` shebangs in the
              # freshly-installed node_modules don't matter in the sandbox.
              cp -r --no-preserve=mode ${proDeps} pro-cache
              npm ci --prefix pro-test --offline --ignore-scripts --cache "$PWD/pro-cache"
              ( cd pro-test && node node_modules/vite/bin/vite.js build && node prerender.mjs )

              # Corpus/sitemap and the frontend build run on the PRISTINE api tree.
              # docker/build-handlers.mjs (below) emits api/**/*.js next to the .ts
              # sources; running it first doubles every source reference and breaks
              # build-crawlable-corpus's source-attribution scan (stale manifest,
              # aviationstack origin). The published docker/Dockerfile likewise
              # builds the corpus without build-handlers.
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

              # nginx config + security-header includes, rendered to store paths so
              # the app's own nginx (see the worldmonitor NixOS module) serves the
              # SPA verbatim without re-deriving its CSP.
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

            # `--omit=optional --ignore-scripts` mirror Dockerfile.relay: skip the
            # native helpers (bufferutil/utf-8-validate) so no toolchain is needed;
            # ws/telegram fall back to pure JS.
            buildPhase = ''
              runHook preBuild

              export HOME="$TMPDIR"

              cp -r --no-preserve=mode ${relayDeps} relay-cache
              npm ci --prefix scripts --offline --omit=dev --omit=optional \
                --ignore-scripts --cache "$PWD/relay-cache"

              # scripts/shared/inventory-facts.generated.json is untracked; the
              # relay requires it at startup (Dockerfile.relay copies it in).
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

              # No --chdir: ais-relay.cjs resolves ../shared and ./lib relative to
              # the script file, so the systemd unit can set a writable
              # WorkingDirectory for any cwd-relative scratch writes.
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

        # Upstash-compatible Redis REST proxy (Node)
        # redis-rest-proxy.mjs's only dependency is `redis`, but upstream installs
        # it ad-hoc (`npm init -y && npm install redis@4`) with no committed
        # manifest, so we carry a minimal pinned package.json + lockfile alongside.
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
