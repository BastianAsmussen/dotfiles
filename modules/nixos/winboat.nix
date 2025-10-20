{
  inputs,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    inputs.winboat.packages.${pkgs.system}.winboat
    pkgs.freerdp
  ];
}
