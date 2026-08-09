{
  flake.nixosModules.ente =
    {
      lib,
      config,
      pkgs,
      options,
      ...
    }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        types
        ;

      cfg = config.ente;

      enteUser = config.services.ente.api.user;
      enteGroup = config.services.ente.api.group;
    in
    {
      options.ente = {
        enable = mkEnableOption "the Ente photos stack";

        uid = mkOption {
          type = types.ints.positive;
          default = 998;
          description = "Stable UID assigned to the Ente system user.";
        };

        gid = mkOption {
          type = types.ints.positive;
          default = 998;
          description = "Stable GID assigned to the Ente system group.";
        };

        apiDomain = mkOption {
          type = types.str;
          default = "ente-api.asmussen.tech";
          description = "Domain for Ente API (museum).";
        };

        webDomains = {
          accounts = mkOption {
            type = types.str;
            default = "ente-accounts.asmussen.tech";
            description = "Domain for Ente Accounts.";
          };

          cast = mkOption {
            type = types.str;
            default = "ente-cast.asmussen.tech";
            description = "Domain for Ente Cast.";
          };

          albums = mkOption {
            type = types.str;
            default = "ente-albums.asmussen.tech";
            description = "Domain for Ente Albums.";
          };

          photos = mkOption {
            type = types.str;
            default = "photos.asmussen.tech";
            description = "Domain for Ente Photos.";
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            users = {
              users.${enteUser}.uid = cfg.uid;
              groups.${enteGroup}.gid = cfg.gid;
            };

            services = {
              garage = {
                enable = true;
                package = pkgs.garage;
                # Garage requires an rpc_secret; provide it via GARAGE_RPC_SECRET so
                # the secret never lands in the world-readable /etc/garage.toml.
                environmentFile = config.sops.templates."garage-rpc-env".path;
                settings = {
                  metadata_dir = "/var/lib/garage/meta";
                  data_dir = "/var/lib/garage/data";
                  replication_mode = "none";
                  rpc_bind_addr = "127.0.0.1:3901";
                  rpc_public_addr = "127.0.0.1:3901";
                  s3_api = {
                    api_bind_addr = "127.0.0.1:3900";
                    s3_region = "garage";
                  };
                };
              };

              ente = {
                api = {
                  enable = true;
                  enableLocalDB = true;
                  nginx.enable = true;
                  domain = cfg.apiDomain;
                  settings = {
                    # The module regenerates local.yaml purely from these settings,
                    # discarding the package's default keys, so museum's encryption,
                    # hash and JWT secrets must be provided explicitly or it cannot
                    # issue tokens.
                    key = {
                      encryption._secret = config.sops.secrets."services/ente/encryption-key".path;
                      hash._secret = config.sops.secrets."services/ente/hash-key".path;
                    };

                    jwt.secret._secret = config.sops.secrets."services/ente/jwt-secret".path;

                    s3 = {
                      are_local_buckets = true;
                      use_path_style_urls = true;
                      b2-eu-cen = {
                        key._secret = config.sops.secrets."services/ente/garage-access-key".path;
                        secret._secret = config.sops.secrets."services/ente/garage-secret-key".path;
                        endpoint = "http://127.0.0.1:3900";
                        region = config.services.garage.settings.s3_api.s3_region;
                        bucket = "ente";
                      };
                    };
                  };
                };

                web = {
                  enable = true;
                  domains = {
                    inherit (cfg.webDomains)
                      accounts
                      cast
                      albums
                      photos
                      ;
                  };
                };
              };

              nginx.virtualHosts =
                let
                  enteHosts = with config.services.ente; [
                    api.domain
                    web.domains.accounts
                    web.domains.cast
                    web.domains.photos
                  ];
                in
                # Ente's NixOS module declares its own virtual hosts; wire them to
                # epsilon's shared wildcard certificate like the custom proxy module.
                builtins.listToAttrs (
                  map (host: {
                    name = host;
                    value.useACMEHost = "asmussen.tech";
                  }) enteHosts
                );
            };

            # Garage has no declarative bucket/key provisioning, so initialize the
            # single-node layout, the "ente" bucket and its access key once garage is
            # up. Every step is idempotent, so re-running it on each boot is harmless.
            systemd.services = {
              garage-bootstrap = {
                description = "Initialize garage layout, bucket and key for Ente";
                after = [ "garage.service" ];
                requires = [ "garage.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  # GARAGE_RPC_SECRET so the CLI can reach the node over RPC.
                  EnvironmentFile = config.sops.templates."garage-rpc-env".path;
                };

                script =
                  let
                    garage = lib.getExe config.services.garage.package;
                    accessKey = config.sops.secrets."services/ente/garage-access-key".path;
                    secretKey = config.sops.secrets."services/ente/garage-secret-key".path;
                  in
                  ''
                    set -euo pipefail

                    # Wait until garage is accepting RPC.
                    for _ in $(seq 1 30); do
                      ${garage} status >/dev/null 2>&1 && break
                      sleep 1
                    done

                    node_id="$(${garage} node id -q | cut -d@ -f1)"

                    # Assign a layout to this single node if it has none yet. An
                    # unassigned node never appears in `layout show`, so its presence
                    # there means the layout is already applied.
                    if ! ${garage} layout show 2>/dev/null | grep -qi "''${node_id:0:10}"; then
                      ${garage} layout assign -z dc1 -c 1TB "$node_id"
                      ${garage} layout apply --version 1
                    fi

                    # Create the bucket if it is missing.
                    ${garage} bucket info ente >/dev/null 2>&1 || ${garage} bucket create ente

                    # Import the fixed access key museum is configured to use.
                    if ! ${garage} key info ente >/dev/null 2>&1; then
                      ${garage} key import --yes -n ente "$(cat ${accessKey})" "$(cat ${secretKey})"
                    fi

                    # Grant the key full access to the bucket (idempotent).
                    ${garage} bucket allow --read --write --owner ente --key ente
                  '';
              };

              # Don't start museum until the bucket it needs exists.
              ente = {
                after = [ "garage-bootstrap.service" ];
                wants = [ "garage-bootstrap.service" ];
              };
            };

            sops = {
              secrets =
                let
                  # Read by museum via the `_secret` mechanism (which runs as the ente
                  # user), so these must be owned by it.
                  enteOwned = {
                    owner = enteUser;
                    group = enteGroup;
                  };
                in
                {
                  # S3 credentials: consumed by museum (`_secret`) and imported into
                  # garage by the bootstrap service (which reads them as root).
                  "services/ente/garage-access-key" = enteOwned;
                  "services/ente/garage-secret-key" = enteOwned;

                  # Museum crypto material (openssl rand -base64 32 / 64 / 32).
                  "services/ente/encryption-key" = enteOwned;
                  "services/ente/hash-key" = enteOwned;
                  "services/ente/jwt-secret" = enteOwned;

                  # Garage cluster RPC secret (openssl rand -hex 32), surfaced via the
                  # env template below rather than the world-readable config file.
                  "services/ente/garage-rpc-secret" = { };
                };

              templates."garage-rpc-env".content = ''
                GARAGE_RPC_SECRET=${config.sops.placeholder."services/ente/garage-rpc-secret"}
              '';
            };
          }

          (lib.optionalAttrs (options ? persistence) {
            persistence.directories = [
              {
                directory = "/var/lib/ente";
                user = enteUser;
                group = enteGroup;
              }
              {
                # Museum's local postgres DB (services.ente.api.enableLocalDB);
                # without this every reboot wipes all users, albums and metadata.
                directory = "/var/lib/postgresql";
                user = "postgres";
                group = "postgres";
              }
              # Garage runs as a DynamicUser, so systemd keeps its real state under
              # /var/lib/private/garage (like meilisearch); /var/lib/garage is only
              # a symlink and would not persist the object data.
              "/var/lib/private/garage"
            ];
          })
        ]
      );
    };
}
