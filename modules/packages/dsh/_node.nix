{
  lib,
  stdenv,
  fetchurl,
}:
let
  ccLib = "${lib.getLib stdenv.cc.cc}/lib";
in
# nixpkgs' nodejs is built with zerocallusedregs hardening, which
# node-addon-require-builtin rejects ("Unsupported/no-getter").
stdenv.mkDerivation (finalAttrs: {
  pname = "nodejs-official";
  version = "24.21.0";

  src = fetchurl {
    url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}-linux-x64.tar.xz";
    hash = "sha256-/Y5Z1aURUQ9qKYr7VI8Yx9KxvkBNi0on2U++SfVsstY=";
  };

  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  # Any RPATH edit makes this binary segfault at startup, so the two
  # non-glibc libraries are linked by absolute path instead.
  postFixup = ''
    patchelf $out/bin/node \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --replace-needed libstdc++.so.6 ${ccLib}/libstdc++.so.6 \
      --replace-needed libgcc_s.so.1 ${ccLib}/libgcc_s.so.1
  '';

  meta = {
    description = "Official nodejs.org build of Node.js";
    homepage = "https://nodejs.org";
    license = lib.licenses.mit;
    mainProgram = "node";
    maintainers = [ lib.maintainers.BastianAsmussen ];
    platforms = [ "x86_64-linux" ];
  };
})
