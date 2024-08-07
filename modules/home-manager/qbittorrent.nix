{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    mkEnableOption
    types
    mkPackageOption
    mkIf
    ;

  file = ''
    [LegalNotice]
    Accepted=${toString cfg.legalNotice}

    [Network]
    Proxy\Type=${cfg.network.proxy.type}
  '';

  cfg = config.programs.qbittorrent;
in {
  options.programs.qbittorrent = {
    enable = mkEnableOption "Enables qBittorrent client.";
    package = mkPackageOption pkgs "qbittorrent" {};

    legalNotice = mkOption {
      default = false;
      example = true;
      type = types.bool;
    };

    network.proxy.type = mkOption {
      default = "None";
      example = "SOCKS5";
      type = types.enum ["None" "SOCKS4" "SOCKS5" "HTTP"];
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional configuration to add to
        {file}`qBittorrent.conf`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."qBittorrent/qBittorrent.conf".text = ''
      ${file}
      ${cfg.extraConfig}
    '';
  };
}
