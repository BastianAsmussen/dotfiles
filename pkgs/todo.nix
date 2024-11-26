{
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "todo";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "BastianAsmussen";
    repo = pname;
    rev = "a22ed281bd1749229652694abab1d0ae7c4ace65";
    hash = "sha256-x6FktzzZ4Il3vg63AD6LzMi7u8dZDM9Um2wBd5txdAM=";
  };

  vendorHash = "sha256-NyM97/7+hA0XBnqjwaLf8lGhNOWJyT0mLw7N4yRomqQ=";
  checkPhase = false;
  meta = {
    description = "A simple ToDo program.";
    homepage = "https://github.com/BastianAsmussen/todo";
    mainProgram = "todo";
  };
}
