{
  userInfo,
  pkgs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.${userInfo.username} = {
    isNormalUser = true;
    description = userInfo.fullName;
    initialPassword = "Password123!";

    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
  };
}
