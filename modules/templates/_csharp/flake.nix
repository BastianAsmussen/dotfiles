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
