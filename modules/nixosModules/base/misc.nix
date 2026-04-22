{
  flake.nixosModules.misc = {pkgs, ...}: {
    boot.tmp.useTmpfs = true;

    environment.wordlist = {
      enable = true;

      lists.WORDLIST = ["${pkgs.scowl}/share/dict/words.txt"];
    };
  };
}
