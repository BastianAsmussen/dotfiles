{
  perSystem =
    { pkgs, ... }:
    let
      features = ../../nixosModules/features;
      template = builtins.fromJSON (builtins.readFile "${features}/router.template.json");
      generator = "${features}/router.generate.py";

      # Empty secrets produce NUL fields matching the redacted reference backup.
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
      # Reproduce a redacted device backup byte-for-byte, including checksums.
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
