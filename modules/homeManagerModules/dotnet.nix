{
  flake.homeModules.dotnet = {pkgs, ...}: let
    dotnetCombined = (with pkgs.dotnetCorePackages;
      combinePackages [
        sdk_10_0
        sdk_9_0
        sdk_8_0
      ])
      .overrideAttrs (_: previousAttrs: {
      postBuild =
        (previousAttrs.postBuild or '''')
        + ''
           for i in $out/sdk/*
           do
             i=$(basename $i)
             length=$(printf "%s" "$i" | wc -c)
             substring=$(printf "%s" "$i" | cut -c 1-$(expr $length - 2))

             i="$substring""00"
             mkdir -p $out/metadata/workloads/''${i/-*}
             touch $out/metadata/workloads/''${i/-*}/userlocal
          done
        '';
    });
  in {
    home = {
      packages = with pkgs; [
        dotnetCombined
        dotnetPackages.Nuget
      ];

      sessionVariables = {
        DOTNET_ROOT = "${dotnetCombined}";
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      };
    };
  };
}
