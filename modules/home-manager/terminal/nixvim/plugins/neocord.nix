config: {
  enable = true;

  settings.blacklist = [
    "${config.programs.password-store.settings.PASSWORD_STORE_DIR}"
  ];
}
