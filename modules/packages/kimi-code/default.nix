{
  perSystem =
    {
      pkgs,
      lib,
      inputs',
      ...
    }:
    {
      packages.kimi-code = inputs'.kimi-code.packages.kimi-code.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./harness.patch ];

        postInstall = ''
          wrapProgram $out/bin/kimi \
            --set KIMI_CODE_NO_AUTO_UPDATE 1 \
            --prefix PATH : ${
              lib.makeBinPath (
                with pkgs;
                [
                  fd
                  ripgrep
                ]
              )
            }
        '';
      });
    };
}
