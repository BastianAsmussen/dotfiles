{
  inputs,
  self,
  ...
}: {
  flake.homeModules.nixvim = {
    config,
    osConfig,
    lib,
    pkgs,
    ...
  }: {
    imports = [
      inputs.nixvim.homeModules.nixvim
    ];

    stylix.targets.nixvim.enable = false;

    programs.nixvim = {
      enable = true;

      imports = [./_nixvim-config.nix];

      defaultEditor = true;
      plugins = {
        # `nixd` needs flake context that is only available inside a NixOS/HM
        # activation.
        lsp.servers.nixd.settings = let
          inherit (osConfig.networking) hostName;

          flake = ''(builtins.getFlake "${self}")'';
          nixos = rec {
            cfg = ''${flake}.nixosConfigurations.${hostName}'';
            opts = ''${cfg}.options'';
          };
        in {
          nixpkgs.expr = ''import ${flake}.inputs.nixpkgs {}'';
          formatting.command = ["${lib.getExe pkgs.alejandra}"];
          options = {
            nixos.expr = nixos.opts;
            lib.expr = ''${nixos.cfg}.lib'';
            home-manager.expr = ''${nixos.opts}.home-manager.users.type.getSubOptions []'';
          };
        };

        # RUSTFLAGS is set via home.sessionVariables, only available inside HM.
        rustaceanvim.settings.server.default_settings.rust-analyzer.check.extraArgs =
          ["--"] ++ (lib.strings.splitString " " config.home.sessionVariables.RUSTFLAGS);
      };
    };
  };
}
