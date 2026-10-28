{
  flake.nixosModules.btop =
    { lib, pkgs, ... }:
    let
      # Bake OpenGL drivers into the RPATH so `dlopen` finds `libnvidia-ml`.
      btop = pkgs.runCommand "btop-nvml" { nativeBuildInputs = [ pkgs.patchelf ]; } ''
        mkdir -p $out/bin
        cp ${lib.getExe pkgs.btop} $out/bin/btop
        chmod +w $out/bin/btop
        patchelf --add-rpath /run/opengl-driver/lib $out/bin/btop
      '';
    in
    {
      security.wrappers.btop = {
        owner = "root";
        group = "root";
        source = "${btop}/bin/btop";
        capabilities = "cap_sys_ptrace,cap_perfmon+ep";
      };

      # Make btop able to read CPU wattage without running as root.
      services.udev.extraRules = ''
        SUBSYSTEM=="powercap", ACTION=="add", RUN+="${lib.getExe' pkgs.coreutils "chmod"} a+r %S%p/energy_uj"
      '';
    };
}
