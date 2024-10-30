{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  buildFHSEnv,
  libseccomp,
  libcap_ng,
  alsa-lib,
  nss,
  gtk3,
  mesa,
  glib,
  nspr,
  dbus,
  at-spi2-atk,
  cups,
  libdrm,
  pango,
  cairo,
  xorg,
  expat,
  libxkbcommon,
}: let
  fullPath = lib.makeLibraryPath ([
      stdenv.cc.cc
      libseccomp
      libcap_ng
      alsa-lib
      nss
      gtk3
      mesa
      glib
      nspr
      dbus
      at-spi2-atk
      cups.lib
      libdrm
      pango
      cairo
      expat
      libxkbcommon
    ]
    ++ (with xorg; [
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
    ]));

  docker-desktop = stdenv.mkDerivation rec {
    pname = "docker-desktop";
    version = "4.34.0";
    rev = "165256";

    src = let
      arch =
        {
          x86_64-linux = "amd64";
        }
        .${stdenv.hostPlatform.system};
    in
      fetchurl {
        url = "https://desktop.docker.com/linux/main/${arch}/${rev}/${pname}-${arch}.deb";
        sha256 = "sha256-qFepUUftBj7GgM2ZIiY8GjhAy16RRPjg2oW1pgbSYYk=";
      };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [dpkg];

    unpackPhase = "dpkg-deb -x ${src} .";

    installPhase = ''
      mkdir -p $out/{bin,lib,share}

      cp -R usr/{bin,lib,share} opt $out/

      # Fix the path in the .desktop files.
      substituteInPlace \
        $out/share/applications/*.desktop \
        --replace-warn /opt/ $out/opt/

      # Fix the path in the .service file.
      substituteInPlace \
        $out/lib/systemd/user/docker-desktop.service \
        --replace-warn /opt/ $out/opt/

      ln -s $out/opt/docker-desktop/Docker\ Desktop $out/bin/docker-desktop

      runHook postInstall
    '';

    preFixup = ''
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${fullPath}:$out/opt/docker-desktop" \
        $out/opt/docker-desktop/Docker\ Desktop
    '';
  };
in
  buildFHSEnv {
    inherit (docker-desktop) pname version;

    targetPkgs = pkgs: [docker-desktop];

    runScript = "docker-desktop";

    meta = with lib; {
      description = "Docker Desktop is an easy-to-install application that enables you to locally build and share containerized applications and microservices.";
      homepage = "https://www.docker.com/products/docker-desktop";
      license = licenses.unfree;
      mainProgram = "docker-desktop";
      platforms = platforms.linux;
      maintainers = with maintainers; [BastianAsmussen];
    };
  }
