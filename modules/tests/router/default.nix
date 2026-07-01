{
  perSystem =
    { pkgs, ... }:
    let
      features = ../../nixosModules/features;
      template = builtins.fromJSON (builtins.readFile "${features}/router.template.json");
      generator = "${features}/router.generate.py";

      # Empty secret files encode to an all-NUL fixed-width field, exactly the
      # bytes the expected fixture has redacted. So rendering the template
      # defaults with empty secrets must reproduce the (secret-free) reference
      # backup byte-for-byte.
      emptySecret = pkgs.writeText "router-test-empty-secret" "";

      planRecords = map (
        record:
        {
          inherit (record)
            key
            len
            type
            kind
            ;
        }
        // (
          if record.secret or false then { secretFile = "${emptySecret}"; } else { value = record.default; }
        )
      ) template.records;

      plan = {
        inherit (template) header_b64 checksum_b64;

        host = "192.168.1.254";
        records = planRecords;
        login = {
          user = "admin";
          passwordFile = "${emptySecret}";
        };
      };

      planFile = pkgs.writeText "router-test-plan.json" (builtins.toJSON plan);
    in
    {
      # Regression guard for the reverse-engineered Icotera backup format: the
      # generator + committed firmware schema must reproduce a real device
      # backup (with secrets redacted) byte-for-byte, with a self-consistent
      # md5 sidecar and the fixed checksum descriptor.
      checks.tests-router =
        pkgs.runCommandLocal "tests-router"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.gnutar
              pkgs.gzip
            ];
          }
          ''
            python3 ${generator} generate ${planFile} backup.bin

            mkdir -p out
            tar -xzf backup.bin -C out

            got_md5="$(md5sum out/db.bin | cut -d' ' -f1)"
            want_md5="$(cat out/db.bin_md5)"
            if [ "$got_md5" != "$want_md5" ]; then
              echo "db.bin_md5 sidecar ($want_md5) does not match db.bin ($got_md5)" >&2
              exit 1
            fi

            if ! cmp -s ${./expected-db.bin} out/db.bin; then
              echo "generated db.bin diverged from the reference fixture" >&2
              cmp ${./expected-db.bin} out/db.bin >&2 || true
              exit 1
            fi

            touch $out
          '';
    };
}
