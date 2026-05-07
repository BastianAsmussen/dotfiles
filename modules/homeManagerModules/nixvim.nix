{
  inputs,
  self,
  ...
}:
{
  flake.homeModules.nixvim =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.nixvim.homeModules.nixvim
      ];

      stylix.targets.nixvim.enable = false;

      programs.nixvim = {
        enable = true;
        imports = [ ./_nixvim-config.nix ];
        defaultEditor = true;
        plugins = {
          # nixd needs activation-only flake context from NixOS/HM.
          lsp.servers.nixd.settings = lib.optionalAttrs (osConfig != null) (
            let
              inherit (osConfig.networking) hostName;

              system = builtins.toJSON pkgs.system;
              flake = ''(builtins.getFlake "${self}")'';

              flakeParts = {
                opts = "${flake}.debug.options";
                perSystemOpts = "${flake}.allSystems.${system}.options";
              };

              nixos = rec {
                cfg = "${flake}.nixosConfigurations.${hostName}";
                opts = "${cfg}.options";
              };

              homeManager.opts = "${nixos.opts}.home-manager.users.type.getSubOptions []";
            in
            {
              nixpkgs.expr = "import ${flake}.inputs.nixpkgs {}";

              options = {
                nixos.expr = nixos.opts;
                home-manager.expr = homeManager.opts;

                # Expose flake-parts and perSystem option roots to nixd.
                flake-parts.expr = flakeParts.opts;
                flake-parts-perSystem.expr = flakeParts.perSystemOpts;

                # Expose narrower option roots without creating new module
                # systems.
                lib.expr = "${nixos.cfg}.lib";
                nixvim.expr = "${homeManager.opts}.programs.nixvim";
                stylix-nixos.expr = "${nixos.opts}.stylix";
                stylix-home.expr = "${homeManager.opts}.stylix";
                sops-nix.expr = "${nixos.opts}.sops";
                disko.expr = "${nixos.opts}.disko";
              };
            }
          );

          # RUSTFLAGS is set via home.sessionVariables, only available inside HM.
          rustaceanvim.settings.server.default_settings.rust-analyzer.check.extraArgs = [
            "--"
          ]
          ++ (lib.strings.splitString " " config.home.sessionVariables.RUSTFLAGS);
        };
      };
    };
}
