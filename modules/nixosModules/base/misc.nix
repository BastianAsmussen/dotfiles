{
  flake.nixosModules.misc =
    { lib, pkgs, ... }:
    {
      boot.tmp.useTmpfs = lib.mkDefault true;

      environment.wordlist = {
        enable = true;
        lists.WORDLIST = [ "${pkgs.scowl}/share/dict/words.txt" ];
      };
    };
}
