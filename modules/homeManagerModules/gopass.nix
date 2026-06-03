{
  flake.homeModules.gopass =
    {
      pkgs,
      config,
      ...
    }:
    {
      home.packages = with pkgs; [
        gopass
        gopass-hibp
        gopass-jsonapi
      ];

      home.shellAliases.pass = "gopass";

      xdg.configFile."gopass/config".source = (pkgs.formats.ini { }).generate "gopass-config" {
        mounts.path = "${config.home.homeDirectory}/.password-store";
        core.autosync = true;
      };
    };
}
