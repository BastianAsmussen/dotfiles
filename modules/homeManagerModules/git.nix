{inputs, ...}: {
  flake.homeModules.git = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      lfs.enable = true;
      maintenance = {
        enable = true;
        repositories = let
          makePath = dir: config.home.homeDirectory + dir;
        in [
          (makePath "/Projects/*/*")
          (makePath "/dotfiles")
          (makePath "/nix-secrets")
        ];
      };

      signing = {
        key = "0x0FE5A355DBC92568";
        signByDefault = true;
      };

      settings = let
        deltaBin = lib.getExe pkgs.delta;
      in {
        user = {
          inherit (inputs.nix-secrets.user) email;

          name = inputs.nix-secrets.user.full-name;
        };

        alias = {
          graph = "log --all --decorate --graph";
          staash = "stash --all";
          hist = "log --pretty=format:\"%Cgreen%h %Creset%cd %Cblue[%cn] %Creset%s%C(yellow)%d%C(reset)\" --graph --date=relative --decorate --all";
          fuck = "commit --amend --message";
          br = "branch";
          st = "status";
          d = "diff";
        };

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
        delta = {
          navigate = true;
          dark = true;
        };

        sendemail = {
          sendmailCmd = "${pkgs.git-protonmail}/bin/git-protonmail";
          from = "${inputs.nix-secrets.user.email}";
        };
      };
    };

    home.packages = [pkgs.git-protonmail];
  };
}
