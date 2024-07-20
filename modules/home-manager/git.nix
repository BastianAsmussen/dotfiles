{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Bastian Asmussen";
    userEmail = "bastian@asmussen.tech";

    signing = {
      key = null;
      signByDefault = true;
    };

    extraConfig = {
      push.autoSetupRemote = true;
      fetch.prune = true; # Automatically delete dead branches.
      pull = {
        ff = false;
        commit = false;
        rebase = true;
        prune = true; # Automatically delete dead branches.
      };

      init.defaultBranch = "master";
    };
  };
}
