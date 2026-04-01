{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {pkgs, ...}: let
        dotnet = pkgs.dotnetCorePackages.sdk_9_0;
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "sample-project";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = [dotnet];

          buildPhase = ''
            export HOME=$TMPDIR
            export DOTNET_CLI_TELEMETRY_OPTOUT=1
            dotnet publish SampleProject/SampleProject.csproj \
              -c Release \
              -o out \
              --self-contained false
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp -r out/* $out/bin/
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            dotnet
            pkgs.omnisharp-roslyn
          ];

          env.DOTNET_ROOT = "${dotnet}";
          env.DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        };
      };
    };
}
