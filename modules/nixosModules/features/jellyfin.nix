{
  flake.nixosModules.jellyfin =
    {
      lib,
      config,
      pkgs,
      options,
      ...
    }:
    let
      inherit (lib)
        mkOption
        types
        ;

      cfg = config.jellyfin;
      svc = config.services.jellyfin;

      user = config.preferences.user.name;
      jellyfinUser = svc.user;
      jellyfinGroup = svc.group;
    in
    {
      options.jellyfin = {
        enable = lib.mkEnableOption "the Jellyfin media stack";

        uid = mkOption {
          type = lib.types.ints.positive;
          default = 996;
        };

        gid = mkOption {
          type = types.ints.positive;
          default = 995;
        };

        mediaGid = mkOption {
          type = types.ints.positive;
          default = 994;
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            users = {
              users.${jellyfinUser}.uid = cfg.uid;

              groups = {
                ${jellyfinGroup}.gid = cfg.gid;

                media = {
                  gid = cfg.mediaGid;
                  members = [
                    user
                    jellyfinUser
                    "shoko"
                  ];
                };
              };
            };

            systemd = {
              tmpfiles.rules = [
                "d /srv/media                  0755 root            media - -"
                "d /srv/media/jellyfin         2770 ${jellyfinUser} media - -"
                "d /srv/media/jellyfin/Shows   2770 ${jellyfinUser} media - -"
                "d /srv/media/jellyfin/Movies  2770 ${jellyfinUser} media - -"
              ];

              services = {
                jellyfin = {
                  unitConfig.RequiresMountsFor = [ "/srv/media" ];
                  serviceConfig = {
                    UMask = lib.mkForce "0002";
                    MemoryMax = "4G";
                  };

                  environment.LC_ALL = config.i18n.defaultLocale;
                };

                shoko.unitConfig.RequiresMountsFor = [ "/srv/media" ];
              };
            };

            # Limit SSRF impact without blocking inbound reverse-proxy connections.
            networking.nftables = {
              enable = true;
              tables."jellyfin-egress" = {
                family = "inet";
                content = ''
                  chain output {
                    type filter hook output priority filter; policy accept;
                    meta skuid ${toString cfg.uid} ct state { established, related } accept
                    meta skuid ${toString cfg.uid} ip daddr 127.0.0.53 udp dport 53 accept
                    meta skuid ${toString cfg.uid} ip daddr 127.0.0.53 tcp dport 53 accept
                    meta skuid ${toString cfg.uid} ip daddr { 127.0.0.0/8, 10.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16 } drop
                    meta skuid ${toString cfg.uid} ip6 daddr { ::1/128, fc00::/7, fe80::/10 } drop
                  }
                '';
              };
            };

            services = {
              jellyfin = {
                enable = true;
                openFirewall = false;
                package = pkgs.jellyfin.overrideAttrs (old: {
                  patches = (old.patches or [ ]) ++ [
                    ./jellyfin/CVE-2026-119549.patch
                    ./jellyfin/CVE-2026-119550.patch
                    ./jellyfin/CVE-2026-119551.patch
                  ];
                });
              };

              meilisearch.enable = true;
              shoko.enable = true;
            };

            environment.systemPackages = with pkgs; [
              svc.package
              jellyfin-web
              jellyfin-ffmpeg
              shoko
            ];
          }

          (lib.optionalAttrs (options ? persistence) {
            persistence = {
              directories = [
                {
                  directory = svc.dataDir;
                  user = jellyfinUser;
                  group = jellyfinGroup;
                }
              ];

              directoriesWithMode.${svc.cacheDir} = {
                mode = "0755";
                user = jellyfinUser;
                group = jellyfinGroup;
              };
            };
          })
        ]
      );
    };
}
