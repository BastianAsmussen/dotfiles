# An isolated nspawn container for long-running autonomous agents.
{ inputs, self, ... }:
{
  flake.nixosModules.agentBox =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        all
        attrNames
        attrValues
        genAttrs
        mapAttrsToList
        mkEnableOption
        mkIf
        mkMerge
        mkOption
        optionalAttrs
        stringLength
        types
        ;

      cfg = config.agentBox;

      iface = "ve-${cfg.name}";
      owner = cfg.workspaceOwner;
      persisted = config.persistence.enable or false;

      # Everything except the public internet.
      privateRanges = lib.concatStringsSep ", " [
        "0.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/10"
        "127.0.0.0/8"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "224.0.0.0/4"
        "240.0.0.0/4"
      ];
    in
    {
      options.agentBox = {
        enable = mkEnableOption "an isolated container for autonomous agents";

        name = mkOption {
          type = types.str;
          default = "agents";
          description = "Container and machine name; the host interface is `ve-<name>`.";
        };

        hostAddress = mkOption {
          type = types.str;
          default = "10.233.1.1";
          description = "Host end of the container's veth link.";
        };

        localAddress = mkOption {
          type = types.str;
          default = "10.233.1.2";
          description = "Container end of the veth link.";
        };

        workspace = mkOption {
          type = types.str;
          default = "/srv/agents";
          description = "Host directory shared with the agent as `~/workspace`, mounted nosuid and nodev.";
        };

        workspaceOwner = mkOption {
          type = types.str;
          default = config.preferences.user.name;
          description = "Host user who owns the workspace. The agent's files appear as theirs.";
        };

        credentials = mkOption {
          type = types.attrsOf types.str;
          default = {
            LLM_API_KEY = "agents/llm-api-key";
          };
          example = {
            DISCORD_TOKEN = "agents/discord-token";
          };
          description = "Credentials handed to the agent. Keys are environment variable names, values are sops secret names.";
        };

        guest = mkOption {
          type = types.deferredModule;
          default = { };
          description = "Extra NixOS configuration for the container, such as `agentBoxGuest` settings.";
        };

        limits = {
          cpuWeight = mkOption {
            type = types.ints.between 1 10000;
            default = 20;
            description = "CPU weight of the container relative to the default of 100.";
          };

          ioWeight = mkOption {
            type = types.ints.between 1 10000;
            default = 20;
            description = "IO weight of the container relative to the default of 100.";
          };

          memoryHigh = mkOption {
            type = types.str;
            default = "50%";
            description = "Memory use above which the container is throttled.";
          };

          memoryMax = mkOption {
            type = types.str;
            default = "60%";
            description = "Hard memory limit of the container.";
          };

          tasksMax = mkOption {
            type = types.ints.positive;
            default = 4096;
            description = "Maximum number of tasks in the container.";
          };
        };
      };

      config = mkIf cfg.enable (mkMerge [
        (optionalAttrs (options ? persistence) {
          persistence = {
            # Hide container roots from host users; nspawn owns what's inside.
            directoriesWithMode."/var/lib/nixos-containers".mode = "0700";

            directories = [
              {
                directory = cfg.workspace;
                user = owner;
                group = owner;
                mode = "0750";
                mountOptions = [
                  "bind"
                  "X-fstrim.notrim"
                  "nosuid"
                  "nodev"
                ];
              }
            ];
          };
        })

        (mkIf (!persisted) {
          systemd.tmpfiles.rules = [
            "d /var/lib/nixos-containers 0700 root root -"
            "d ${cfg.workspace} 0750 ${owner} ${owner} -"
          ];

          # Container root can create root-owned files through the idmapped mount.
          fileSystems.${cfg.workspace} = {
            device = cfg.workspace;
            fsType = "none";
            options = [
              "bind"
              "nosuid"
              "nodev"
              "x-mount.mkdir"
            ];
          };
        })

        {
          assertions = [
            {
              # Longer names get a truncated interface the firewall won't match.
              assertion = stringLength cfg.name <= 11;
              message = "agentBox.name must be at most 11 characters.";
            }
            {
              assertion = all (name: builtins.match "[A-Z_][A-Z0-9_]*" name != null) (attrNames cfg.credentials);
              message = "agentBox.credentials keys must be uppercase environment variable names.";
            }
          ];

          containers.${cfg.name} = {
            autoStart = true;
            privateNetwork = true;
            privateUsers = "pick";
            inherit (cfg) hostAddress localAddress;

            # Host switches must not kill running agents; `just agent-reload` applies changes.
            restartIfChanged = false;

            extraFlags = [
              "--bind=${cfg.workspace}:/home/agent/workspace:idmap"
            ]
            ++ mapAttrsToList (
              name: secret: "--load-credential=${name}:${config.sops.secrets.${secret}.path}"
            ) cfg.credentials;

            config = {
              imports = [
                self.nixosModules.agentBoxGuest
                cfg.guest
              ];

              nixpkgs.pkgs = pkgs.extend inputs.nix-openclaw.overlays.default;
              agentBoxGuest.credentials = attrNames cfg.credentials;
            };
          };

          # nspawn reads these as root and passes copies in as credentials.
          sops.secrets = genAttrs (attrValues cfg.credentials) (_: { });

          systemd.services."container@${cfg.name}".serviceConfig = {
            CPUWeight = cfg.limits.cpuWeight;
            IOWeight = cfg.limits.ioWeight;
            MemoryHigh = cfg.limits.memoryHigh;
            MemoryMax = cfg.limits.memoryMax;
            TasksMax = cfg.limits.tasksMax;
          };

          networking = {
            nat = {
              enable = true;
              internalInterfaces = [ iface ];
            };

            nftables = {
              enable = true;

              # Scoped to the container's interface, so podman, libvirt and PIA are untouched.
              tables.agent-box = {
                family = "inet";
                content = ''
                  chain input {
                    type filter hook input priority filter; policy accept;
                    iifname "${iface}" ct state established,related accept
                    iifname "${iface}" drop
                  }

                  chain forward {
                    type filter hook forward priority filter; policy accept;
                    iifname "${iface}" meta nfproto ipv6 drop
                    iifname "${iface}" ip daddr { ${privateRanges} } drop
                    oifname "${iface}" ct state established,related accept
                    oifname "${iface}" drop
                  }
                '';
              };
            };
          };
        }
      ]);
    };
}
