{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  alsa-lib,
  libxkbcommon,
  mesa,
  glib,
  nss,
  dbus,
  at-spi2-atk,
  cups,
  gtk3,
  libseccomp,
  libcap_ng,
}:
stdenv.mkDerivation rec {
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

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [
    dpkg
    alsa-lib
    libxkbcommon
    mesa
    glib
    nss
    dbus
    at-spi2-atk
    cups.lib
    gtk3
    libseccomp.lib
    libcap_ng
  ];

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

    ln -s $out/opt/docker-desktop/bin/* $out/bin

    mkdir -p $out/libexec/docker/cli-plugins
    ln -s $out/lib/docker/cli-plugins/* $out/libexec/docker/cli-plugins
    find . -type f ! -name "docker-desktop" ! -name "env-vars" -exec ln -s "$out/libexec/docker/cli-plugins/{}" $out/bin/{} \;

    runHook postInstall
  '';

  meta = with lib; {
    description = "Docker Desktop is an easy-to-install application that enables you to locally build and share containerized applications and microservices.";
    homepage = "https://www.docker.com/products/docker-desktop";
    license = licenses.unfree;
    mainProgram = "docker-desktop";
    platforms = platforms.linux;
    maintainers = with maintainers; [BastianAsmussen];
  };
}
