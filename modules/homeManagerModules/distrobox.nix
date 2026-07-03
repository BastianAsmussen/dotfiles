{
  flake.homeModules.distrobox =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.distrobox ];

      xdg.configFile."distrobox/distrobox.conf".text = ''
        container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
        container_always_pull="0"
        container_image_default="docker.io/library/archlinux:latest"
        container_name_default="archlinux"
        non_interactive="1"
        init_hooks="echo 'export PATH=$HOME/.nix-profile/bin:$PATH
        export NIX_SSL_CERT_FILE=$HOME/.nix-profile/etc/ssl/certs/ca-bundle.crt' > /etc/profile.d/nix-user-profile.sh"
        pre_init_hooks="source /etc/profile.d/nix-user-profile.sh 2>/dev/null || true"
      '';
    };
}
