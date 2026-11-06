{ inputs, withSystem, ... }:
{
  flake.nixosModules.website =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Cross-compile natively instead of building aarch64 Go through QEMU.
      crossPackage = withSystem "x86_64-linux" (
        { pkgs, ... }:
        (pkgs.pkgsCross.aarch64-multiplatform.extend inputs.website.overlays.default).website
      );
    in
    {
      options.website-extras.exposePublicly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to serve the website at asmussen.tech through Caddy.";
      };

      imports = [ inputs.website.nixosModules.default ];

      config = {
        services = {
          website = {
            enable = true;
            port = lib.mkDefault 8080;
            package = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-linux") crossPackage;
          };

          caddy.virtualHosts."asmussen.tech".extraConfig =
            lib.mkIf config.website-extras.exposePublicly "reverse_proxy localhost:${toString config.services.website.port}";
        };
      };
    };
}
