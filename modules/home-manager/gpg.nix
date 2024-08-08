{
  lib,
  config,
  osOptions,
  pkgs,
  ...
}: let
  cfg = config.gpg;

  keyDir = ../../keys;

  getAllKeys = keyDir: builtins.attrNames (builtins.readDir keyDir);
  isKeyAllowed = keyName: disallowedKeys: builtins.elem keyName disallowedKeys;
  filterAllowedKeys = allKeys: disallowedKeys: builtins.filter (key: !isKeyAllowed key disallowedKeys) allKeys;
  mapKeyPaths = keys: keyDir: builtins.map (keyName: {source = "${keyDir}/${keyName}";}) keys;

  findMissingKeys = keys: builtins.filter (key: !builtins.elem key (getAllKeys keyDir)) keys;
  missingKeys = findMissingKeys cfg.disallowedKeys;
in {
  options.gpg = with lib; {
    enable = mkEnableOption "Enables GPG.";
    disallowedKeys = mkOption {
      default = [];
      description = "Keys that you don't wish to import.";
      type = with types; listOf str;
    };
  };

  config = lib.mkIf cfg.enable {
    warnings =
      if builtins.length missingKeys > 0
      then [
        ''
          The following keys specified in `disallowedKeys` are not present in "${keyDir}":
          ${builtins.concatStringsSep "\n" (builtins.map (key: " - ${key}") missingKeys)}
        ''
      ]
      else [];

    programs.gpg = {
      enable = true;

      # Read public keys from the `keys` directory.
      publicKeys = mapKeyPaths (filterAllowedKeys (getAllKeys keyDir) cfg.disallowedKeys) keyDir;

      scdaemonSettings.disable-ccid = osOptions.yubiKey.enable; # Disable CCID conflicts when using a YubiKey.
      settings = {
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";
        charset = "utf-8";
        fixed-list-mode = true;
        no-comments = true;
        no-emit-version = true;
        keyid-format = "0xlong";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        with-fingerprint = true;
        require-cross-certification = true;
        no-symkey-cache = true;
        use-agent = true;
        throw-keyids = true;
      };
    };
  };
}
