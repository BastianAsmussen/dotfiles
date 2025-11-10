{inputs, ...}: {
  flake.nixosModules.extra_hjem = {config, ...}: let
    username = config.preferences.user.name;
  in {
    imports = [
      inputs.hjem.nixosModules.default
    ];

    config = {
      hjem = {
        clobberByDefault = true;
        users."${username}" = {
          enable = true;

          directory = "/home/${username}";
          user = "${username}";
        };
      };
    };
  };
}
