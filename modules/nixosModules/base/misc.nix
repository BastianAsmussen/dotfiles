{
  flake.nixosModules.misc = {pkgs, ...}: {
    environment.wordlist = {
      enable = true;

      lists.WORDLIST = ["${pkgs.scowl}/share/dict/words.txt"];
    };
  };
}
