{ inputs, ... }:
{
  flake.homeModules.sops =
    {
      config,
      osConfig ? null,
      hostName ? null,
      ...
    }:
    let
      resolvedHostName = if osConfig != null then osConfig.networking.hostName else hostName;
    in
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = "${toString inputs.nix-secrets}/hosts/${resolvedHostName}.yaml";
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      };
    };
}
