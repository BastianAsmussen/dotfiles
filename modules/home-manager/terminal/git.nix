{
  config,
  userInfo,
  ...
}: {
  programs.git = {
    enable = true;

    lfs.enable = true;
    maintenance = {
      enable = true;

      repositories = let
        makePath = dir: config.home.homeDirectory + dir;
      in [
        (makePath "/dotfiles")
        (makePath "/Projects/*")
      ];
    };

    userName = userInfo.fullName;
    userEmail = userInfo.email;

    signing = {
      key = null;
      signByDefault = true;
    };

    aliases.staash = "stash --all";

    extraConfig = {
      push = {
        autoSetupRemote = true;
        default = "current";
      };

      fetch = {
        prune = true; # Automatically delete dead branches.
        writeCommitGraph = true; # Incrementally build commit graph.
      };

      pull = {
        ff = "only"; # Force linear commit history by disallowing unmergable fast-forwards.
        commit = false;
        rebase = true;
        prune = true; # Automatically delete dead branches.
      };

      merge.stat = true;
      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      # Automatically resolve merge conflicts if they've been seen before.
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      column.ui = "auto"; # Make `git branch` prettier.
      branch = {
        sort = "-committerdate"; # Sort by most recent commit.
        autosetupmerge = true;
      };

      core.whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
      repack.usedeltabaseoffset = true;
      init.defaultBranch = "master";
    };
  };
}
