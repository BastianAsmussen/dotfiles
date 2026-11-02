{
  flake.homeModules.distrobox =
    {
      lib,
      pkgs,
      osConfig ? null,
      ...
    }:
    let
      podman = osConfig.virtualisation.podman.package or pkgs.podman;

      # Refresh with: nix run --inputs-from . nixpkgs#nix-prefetch-docker -- \
      #                 --image-name archlinux --image-tag latest --os linux \
      #                 --arch amd64 --quiet
      archlinuxBase = pkgs.dockerTools.pullImage {
        imageName = "archlinux";
        imageDigest = "sha256:ece6c971fec3c532fd508bce299a446deaf469feecbfe7c353e995bc1a5e7bba";
        hash = "sha256-X3phK5YwSTMrKjvBeI4jmz7rRnEnvjy09DA6u+ynnPE=";
        finalImageName = "archlinux";
        finalImageTag = "latest";
        os = "linux";
        arch = "amd64";
      };

      pacmanConf = pkgs.writeText "pacman.conf" ''
        [options]
        HoldPkg = pacman glibc
        Architecture = auto
        Color
        ILoveCandy
        VerbosePkgLists
        ParallelDownloads = 10
        DownloadUser = alpm
        DisableSandboxFilesystem
        SigLevel = Required DatabaseOptional
        LocalFileSigLevel = Optional

        [core]
        Include = /etc/pacman.d/mirrorlist

        [extra]
        Include = /etc/pacman.d/mirrorlist

        [multilib]
        Include = /etc/pacman.d/mirrorlist
      '';

      makepkgConf = pkgs.writeText "makeflags.conf" ''
        MAKEFLAGS="--jobs=$(nproc)"
      '';

      image = pkgs.dockerTools.buildImage {
        name = "archlinux-distrobox";
        tag = "latest";
        fromImage = archlinuxBase;
        extraCommands = ''
          install -Dm644 ${pacmanConf} etc/pacman.conf
          install -Dm644 ${makepkgConf} etc/makepkg.conf.d/makeflags.conf
        '';

        config = {
          Cmd = [ "/usr/bin/bash" ];
          Env = [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            "LANG=C.UTF-8"
          ];
        };
      };
    in
    {
      home.packages = [ pkgs.distrobox ];

      systemd.user.services.distrobox-image = {
        Unit.Description = "Load the custom Arch Linux distrobox image into Podman";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${lib.getExe podman} load --input ${image}";
        };

        Install.WantedBy = [ "default.target" ];
      };

      xdg.configFile."distrobox/distrobox.conf".text = ''
        container_additional_volumes="/nix/store:/nix/store:ro /etc/profiles/per-user:/etc/profiles/per-user:ro /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"
        container_always_pull="0"
        container_image_default="localhost/${image.imageName}:${image.imageTag}"
        container_name_default="archlinux"
        non_interactive="1"
        init_hooks="echo 'export PATH=$HOME/.nix-profile/bin:$PATH
        export NIX_SSL_CERT_FILE=$HOME/.nix-profile/etc/ssl/certs/ca-bundle.crt' > /etc/profile.d/nix-user-profile.sh"
        pre_init_hooks="source /etc/profile.d/nix-user-profile.sh 2>/dev/null || true"
      '';
    };
}
