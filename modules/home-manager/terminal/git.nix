{userInfo, ...}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = userInfo.fullName;
    userEmail = userInfo.email;

    signing = {
      key = null;
      signByDefault = true;
    };

    aliases.staash = "stash --all";

    extraConfig = {
      push.autoSetupRemote = true;

      fetch = {
        prune = true; # Automatically delete dead branches.
        writeCommitGraph = true; # Incrementally build commit graph.
      };

      pull = {
        ff = false;
        commit = false;
        rebase = true;
        prune = true; # Automatically delete dead branches.
      };

      rerere.enabled = true; # Automatically resolve merge conflicts if they've been seen before.

      column.ui = "auto"; # Make `git branch` prettier.
      branch.sort = "-committerdate"; # Sort by most recent commit.

      init.defaultBranch = "master";
    };
  };
}
