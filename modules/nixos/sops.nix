{pkgs, ...}: {
  environment.systemPackages = [pkgs.sops];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
}
