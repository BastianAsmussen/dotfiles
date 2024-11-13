{
  pkgs,
  lib,
}:
pkgs.stdenv.mkDerivation {
  name = "tmux-sessionizer";
  src = pkgs.fetchFromGitHub {
    owner = "BastianAsmussen";
    repo = "tmux-sessionizer";
    rev = "c0777f69faed032fa7351a881e86ed37ac4d6b37";
    hash = "sha256-byMOiXvCh0XO9W4klfJIsVEql+bMcxwf39I7+nTb8yM=";
  };

  buildInputs = [pkgs.bash];
  nativeBuildInputs = [pkgs.makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    cp tmux-sessionizer $out/bin/tmux-sessionizer
    wrapProgram $out/bin/tmux-sessionizer \
      --prefix PATH : ${lib.makeBinPath (with pkgs; [tmux fzf])}
  '';

  meta = {
    description = "its a script that does everything awesome at all times";
    homepage = "https://github.com/BastianAsmussen/tmux-sessionizer";
    mainProgram = "tmux-sessionizer";
  };
}
