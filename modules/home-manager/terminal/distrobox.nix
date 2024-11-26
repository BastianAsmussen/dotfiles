{pkgs, ...}: {
  home.packages = [pkgs.distrobox];

  xdg.configFile."distrobox/distrobox.conf".text = ''
    container_additional_volumes="/nix/store:/nix/store:ro /etc/static/profiles/per-user:/etc/profiles/per-user:ro"
    container_always_pull="1"
    container_image_default="archlinux:latest"
    container_name_default="archlinux"
    non_interactive="1"
  '';
}
