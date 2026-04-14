{
  self,
  inputs,
  ...
}: let
  # Evaluate NixOS modules without booting a VM.
  evalNixos = modules:
    (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit self inputs;
        inherit (self) lib;

        outputs = self;
      };

      inherit modules;
    })
    .config;

  # Override nix-secrets-derived defaults so eval tests are hermetic.
  testUser = {
    preferences.user = {
      name = "testuser";
      fullName = "Test User";
      email = "test@example.com";
    };
  };
in {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    mkEvalTest = name: modules: assertFn: let
      cfg = evalNixos modules;
      ok = assertFn cfg;
    in
      assert lib.assertMsg ok "nixos-eval-${name}: assertion failed";
        pkgs.runCommandLocal "nixos-eval-${name}" {} "touch $out";
  in {
    checks =
      {
        # `preferences.monitors` Option Tests.
        nixos-eval-monitors-default-empty =
          mkEvalTest "monitors-default-empty"
          [self.nixosModules.base testUser]
          (cfg: cfg.preferences.monitors == {});

        nixos-eval-monitor-vrr-default-off =
          mkEvalTest "monitor-vrr-default-off"
          [
            self.nixosModules.base
            testUser
            {
              preferences.monitors.DP-1 = {
                width = 1920;
                height = 1080;
              };
            }
          ]
          (cfg: cfg.preferences.monitors.DP-1.vrr == "off");

        nixos-eval-monitor-scale-default-one =
          mkEvalTest "monitor-scale-default-one"
          [
            self.nixosModules.base
            testUser
            {
              preferences.monitors.DP-1 = {
                width = 1920;
                height = 1080;
              };
            }
          ]
          (cfg: cfg.preferences.monitors.DP-1.scale == 1.0);

        nixos-eval-monitor-enabled-default-true =
          mkEvalTest "monitor-enabled-default-true"
          [
            self.nixosModules.base
            testUser
            {
              preferences.monitors.DP-1 = {
                width = 1920;
                height = 1080;
              };
            }
          ]
          (cfg: cfg.preferences.monitors.DP-1.enabled);

        nixos-eval-monitor-disabled-flag =
          mkEvalTest "monitor-disabled-flag"
          [
            self.nixosModules.base
            testUser
            {
              preferences.monitors.DP-1 = {
                width = 1920;
                height = 1080;
                enabled = false;
              };
            }
          ]
          (cfg: !cfg.preferences.monitors.DP-1.enabled);

        # `preferences.user` Option Tests.
        nixos-eval-user-wheel-group =
          mkEvalTest "user-wheel-group"
          [self.nixosModules.base testUser]
          (cfg: builtins.elem "wheel" cfg.users.users.testuser.extraGroups);

        nixos-eval-user-is-normal =
          mkEvalTest "user-is-normal"
          [self.nixosModules.base testUser]
          (cfg: cfg.users.users.testuser.isNormalUser);

        nixos-eval-zsh-system-enabled =
          mkEvalTest "zsh-system-enabled"
          [self.nixosModules.base testUser]
          (cfg: cfg.programs.zsh.enable);

        # SSH Module.
        nixos-eval-ssh-no-password-auth =
          mkEvalTest "ssh-no-password-auth"
          [self.nixosModules.base self.nixosModules.ssh testUser]
          (cfg: !cfg.services.openssh.settings.PasswordAuthentication);

        nixos-eval-ssh-no-root-login =
          mkEvalTest "ssh-no-root-login"
          [self.nixosModules.base self.nixosModules.ssh testUser]
          (cfg: cfg.services.openssh.settings.PermitRootLogin == "no");

        nixos-eval-ssh-pubkey-only =
          mkEvalTest "ssh-pubkey-only"
          [self.nixosModules.base self.nixosModules.ssh testUser]
          (cfg: cfg.services.openssh.settings.AuthenticationMethods == "publickey");

        # Bluetooth Module.
        nixos-eval-bluetooth-enabled =
          mkEvalTest "bluetooth-enabled"
          [self.nixosModules.base self.nixosModules.bluetooth testUser]
          (cfg: cfg.hardware.bluetooth.enable);

        nixos-eval-bluetooth-power-on-boot =
          mkEvalTest "bluetooth-power-on-boot"
          [self.nixosModules.base self.nixosModules.bluetooth testUser]
          (cfg: cfg.hardware.bluetooth.powerOnBoot);
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        # VM tests: runtime behaviour (x86_64 only)
        nixos-vm-user-created = pkgs.testers.nixosTest {
          name = "user-created";
          nodes.machine = {lib, ...}: {
            imports = [self.nixosModules.base];
            preferences.user = {
              name = lib.mkForce "alice";
              fullName = lib.mkForce "Alice Test";
              email = lib.mkForce "alice@test.com";
            };

            preferences.user.authorizedKeyFiles = [];
            virtualisation.graphics = false;
          };

          testScript = ''
            machine.wait_for_unit("multi-user.target")
            machine.succeed("id alice")
            machine.succeed("id alice | grep -q wheel")
            machine.succeed("getent passwd alice | grep -q zsh")
          '';
        };

        nixos-vm-ssh-running = pkgs.testers.nixosTest {
          name = "ssh-running";
          nodes.machine = {lib, ...}: {
            imports = [self.nixosModules.base self.nixosModules.ssh];
            preferences.user = {
              name = lib.mkForce "alice";
              fullName = lib.mkForce "Alice Test";
              email = lib.mkForce "alice@test.com";
            };

            preferences.user.authorizedKeyFiles = [];
            virtualisation.graphics = false;
          };

          testScript = ''
            machine.wait_for_unit("sshd.service")
            machine.succeed("ss -tlnp | grep -q :22")
          '';
        };
      };
  };
}
