{
  config,
  userInfo,
  lib,
  pkgs,
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

    aliases = {
      graph = "log --all --decorate --graph";
      staash = "stash --all";
      hist = "log --pretty=format:\"%Cgreen%h %Creset%cd %Cblue[%cn] %Creset%s%C(yellow)%d%C(reset)\" --graph --date=relative --decorate --all";
      fuck = "commit --amend -m";
      br = "branch";
      st = "status";
      d = "diff";
    };

    extraConfig = let
      deltaBin = lib.getExe pkgs.delta;
    in {
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

      merge = {
        stat = true;
        conflictstyle = "zdiff3"; # Better conflict style.
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
      };

      # Automatically resolve merge conflicts if they've been seen before.
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      branch = {
        sort = "-committerdate"; # Sort by most recent commit.
        autosetupmerge = true;
      };

      repack.usedeltabaseoffset = true;
      init.defaultBranch = "master";
      core = {
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        pager = deltaBin;
      };

      interactive.diffFilter = "${deltaBin} --color-only";
      delta.navigate = true;
    };
  };
}
