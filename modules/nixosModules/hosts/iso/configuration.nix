{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs self;
      inherit (self) lib;

      outputs = self;
    };

    modules = [
      self.nixosModules.hostIso
    ];
  };

  flake.nixosModules.hostIso = {
    modulesPath,
    pkgs,
    lib,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      (modulesPath + "/installer/cd-dvd/channel.nix")

      # Base modules.
      self.nixosModules.base
      self.nixosModules.language
    ];

    networking.hostName = "iso";

    nixpkgs = {
      hostPlatform = lib.mkDefault "x86_64-linux";
      config.allowUnfree = true;
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # The default compression-level is very slow; zstd level 3 is much faster.
    isoImage.squashfsCompression = "zstd -Xcompression-level 3";

    # Embed the build timestamp into /etc/isoBuildTime for easy identification.
    environment.etc.isoBuildTime.text = lib.mkDefault (
      lib.readFile "${
        pkgs.runCommand "timestamp" {
          env.when = builtins.currentTime;
        } "echo -n `date -d @$when +%Y-%m-%d_%H-%M-%S` > $out"
      }"
    );

    # Show the ISO build time in the bash prompt.
    programs.bash.promptInit = ''
      ISO_BUILD_TIME=$(cat /etc/isoBuildTime)
      export PS1="\\[\\033[01;32m\\]\\u@\\h-$ISO_BUILD_TIME\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\$ "
    '';

    environment.systemPackages = [
      pkgs.git
      self.packages.${pkgs.stdenv.hostPlatform.system}.neovim-minimal
    ];

    services = {
      qemuGuest.enable = true;
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = lib.mkForce "yes";
          PasswordAuthentication = false;
        };
      };
    };

    boot.supportedFilesystems = lib.mkForce [
      "btrfs"
      "vfat"
    ];

    # Prevent the screen from turning off.
    systemd = {
      services.sshd.wantedBy = lib.mkForce ["multi-user.target"];
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };

    users.users.root.openssh.authorizedKeys.keyFiles =
      lib.custom.keys.default.sshPaths;
  };
}
