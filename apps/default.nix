{
  inputs,
  pkgs,
  lib,
}: {
  glove80 = {
    type = "app";
    program = lib.getExe (import ./glove80 {inherit inputs pkgs;});
  };
}
