{
  flake.nixosModules.btop = {
    lib,
    pkgs,
    ...
  }: let
    # Bake the NVIDIA library path into RPATH; AT_SECURE strips LD_LIBRARY_PATH.
    btop = pkgs.runCommand "btop-nvml" {nativeBuildInputs = [pkgs.patchelf];} ''
      mkdir -p $out/bin
      cp ${lib.getExe pkgs.btop} $out/bin/btop
      chmod +w $out/bin/btop
      patchelf --add-rpath /run/opengl-driver/lib $out/bin/btop
    '';
  in {
    security.wrappers.btop = {
      owner = "root";
      group = "root";
      source = "${btop}/bin/btop";
      capabilities = "cap_sys_ptrace,cap_perfmon+ep";
    };

    # Make powercap energy counters readable so btop can show CPU wattage.
    services.udev.extraRules = ''
      SUBSYSTEM=="powercap", ACTION=="add", RUN+="${lib.getExe' pkgs.coreutils "chmod"} a+r %S%p/energy_uj"
    '';
  };
}
