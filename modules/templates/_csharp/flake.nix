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
        packages.default = pkgs.buildDotnetModule {
          pname = "sample-project";
          version = "0.1.0";

          src = ./.;
          projectFile = "SampleProject/SampleProject.csproj";
          nugetDeps = ./deps.json;
          dotnet-sdk = dotnet;
          dotnet-runtime = pkgs.dotnetCorePackages.runtime_9_0;
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
