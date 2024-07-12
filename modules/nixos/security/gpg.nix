{
  lib,
  config,
  ...
}: {
  options.gpg.enable = lib.mkEnableOption "Enable GPG agent.";

  config = lib.mkIf config.gpg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = config.yubiKey.enable;
    };
  };
}
