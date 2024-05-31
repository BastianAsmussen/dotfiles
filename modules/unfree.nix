{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) (
      map lib.getName [
        pkgs.discord
        pkgs.steam
        pkgs.steam-run
        pkgs.steam-original
      ]
    );

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    discord
  ];
}
