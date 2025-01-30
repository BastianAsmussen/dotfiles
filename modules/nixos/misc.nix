{pkgs, ...}: {
  # Enable system-wide wordlist. Some Pandoc filters and other programs depend
  # on wordlist available in system path, and shells do not work. I don't like
  # this, but it's a necessary evil.
  environment.wordlist = {
    enable = true;

    lists.WORDLIST = ["${pkgs.scowl}/share/dict/words.txt"];
  };
}
