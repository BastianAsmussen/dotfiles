{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.learnharness =
        let
          electron = pkgs.electron_44;
          libDir = "${placeholder "out"}/lib/learnharness";
        in
        pkgs.buildNpmPackage (finalAttrs: {
          pname = "learnharness";
          version = "0.5.0";

          src = pkgs.fetchFromGitHub {
            owner = "amosblomqvist";
            repo = "learnharness";
            tag = "v${finalAttrs.version}";
            hash = "sha256-hUhTUsblmdnkgD7DM6oEEQCFFNPoPUX1zotCgl+hKCY=";
          };

          patches = [ ./mcp.patch ];

          npmDepsHash = "sha256-+OlIwC9UD7T15Z03IJjF2cNt9wk0/kqcBbviylWdRIA=";

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            copyDesktopItems
            makeWrapper
            removeReferencesTo
          ];

          buildInputs = [ pkgs.stdenv.cc.cc.lib ];

          env.NEXT_TELEMETRY_DISABLED = "1";

          # next/font/google fetches at build time, so serve the same faces locally.
          # The shell runs under nixpkgs' electron, so process.resourcesPath and a
          # bare execPath both point into electron's own store path.
          postPatch = ''
            install -Dm444 "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono[wght].ttf" app/fonts/JetBrainsMono.ttf
            install -Dm444 ${pkgs.source-sans}/share/fonts/truetype/SourceSans3VF-Upright.ttf app/fonts/SourceSans3.ttf

            substituteInPlace app/layout.tsx \
              --replace-fail 'import { JetBrains_Mono, Source_Sans_3 } from "next/font/google";' \
                'import localFont from "next/font/local";' \
              --replace-fail 'JetBrains_Mono({ subsets: ["latin"],' \
                'localFont({ src: "./fonts/JetBrainsMono.ttf", weight: "100 800",' \
              --replace-fail 'Source_Sans_3({ subsets: ["latin"],' \
                'localFont({ src: "./fonts/SourceSans3.ttf", weight: "200 900",'

            substituteInPlace electron/main.cjs \
              --replace-fail 'path.join(process.resourcesPath, "server", "standalone", "server.js")' \
                '"${libDir}/server/server.js"'

            substituteInPlace src/agent/subagents/headless.ts \
              --replace-fail 'process.versions.electron ? ["--browser-service"]' \
                'process.versions.electron ? ["${libDir}/app", "--browser-service"]'
          '';

          postBuild = ''
            node scripts/build-server.mjs
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p ${libDir}/app/node_modules
            cp -r .next/standalone ${libDir}/server
            cp -r electron package.json ${libDir}/app/
            cp -r node_modules/jose ${libDir}/app/node_modules/

            # Electron runs the server; this unused CLI shebang would pull in nodejs.
            remove-references-to -t ${pkgs.nodejs} \
              ${libDir}/server/node_modules/@puppeteer/browsers/lib/main-cli.js

            install -Dm444 build/icon.png $out/share/icons/hicolor/512x512/apps/learnharness.png

            makeWrapper ${lib.getExe electron} $out/bin/learnharness \
              --add-flags ${libDir}/app

            runHook postInstall
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "learnharness";
              desktopName = "LearnHarness";
              comment = finalAttrs.meta.description;
              exec = "learnharness %U";
              icon = "learnharness";
              categories = [ "Education" ];
              startupWMClass = "learnharness";
            })
          ];

          meta = {
            description = "Agent harness for learning with adaptive teaching, practice, and a knowledge graph";
            homepage = "https://github.com/amosblomqvist/learnharness";
            license = lib.licenses.agpl3Only;
            mainProgram = "learnharness";
            maintainers = [ lib.maintainers.BastianAsmussen ];
            platforms = lib.platforms.linux;
          };
        });
    };
}
