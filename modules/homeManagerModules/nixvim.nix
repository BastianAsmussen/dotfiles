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

      # Needed for TypeScript.
      home.packages = [ pkgs.typescript-language-server ];

      programs.nixvim = _: {
        imports = [ self.nixvimModules.default ];
        nixpkgs.pkgs = pkgs;

        enable = true;
        defaultEditor = true;
        plugins = {
          # `nixd` needs flake context that is only available inside a NixOS/HM
          # activation.
          # nixd needs osConfig to resolve the host's NixOS configuration.
          # In standalone home-manager (osConfig == null) these settings are skipped.
          lsp.servers.nixd.settings = lib.optionalAttrs (osConfig != null) (
            let
              inherit (osConfig.networking) hostName;

              system = builtins.toJSON pkgs.stdenv.hostPlatform.system;
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

                # Useful when editing modules/flake-parts.nix, perSystem modules,
                # checks, formatter, pre-commit hooks, dev shells, etc.
                flake-parts.expr = flakeParts.opts;
                flake-parts-perSystem.expr = flakeParts.perSystemOpts;

                # Convenience focused views. These are not new module systems;
                # they are narrower option roots.
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
