{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Bastian Asmussen";
    userEmail = "bastian@asmussen.tech";

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "master";
    };
  };
}
