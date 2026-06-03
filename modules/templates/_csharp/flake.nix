{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        { pkgs, ... }:
        {
          packages.default = pkgs.buildDotnetModule {
            pname = "sample-project";
            version = "0.1.0";
            src = ./.;

            projectFile = "sample-project.csproj";

            # Regenerate after changing dependencies:
            #   nix build .#default.passthru.fetch-deps && ./result deps.json
            nugetDeps = ./deps.json;
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              dotnet-sdk
              csharp-ls
            ];

            env.DOTNET_ROOT = "${pkgs.dotnet-sdk}";
          };
        };
    };
}
