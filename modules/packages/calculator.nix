{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.calculator =
        let
          drv = pkgs.writeShellScriptBin "=" ''
            cat << EOF | ${lib.getExe pkgs.bc}
            scale=2
            $@
            EOF

            exit 0
          '';
        in
        drv
        // {
          meta = {
            description = "Quick-and-dirty command-line calculator backed by bc.";
            license = lib.licenses.mit;
            maintainers = [ ];
            platforms = lib.platforms.unix;
            mainProgram = "=";
          };
        };
    };
}
