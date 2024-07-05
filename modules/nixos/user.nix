{pkgs, ...}: {
  users.users.bastian = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker" "libvirtd"];
    shell = pkgs.zsh;
    description = "Bastian Asmussen";

    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPc8Md/RuoiNaFIieZ2hTQ6z2R+bE8xealvVhs4omoq3AAAABHNzaDo= bastian@asmussen"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUlnObPZOCziYmtmSH/+lPBwQwEx8mpFh0YLF2YmBsO"
    ];
  };
}
