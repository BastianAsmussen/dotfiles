{
  lib,
  config,
  osOptions,
  ...
}: let
  cfg = config.gpg;

  keyDir = ../../keys;

  # Function to get all key names in the specified directory.
  getAllKeys = keyDir: builtins.attrNames (builtins.readDir keyDir);

  # Function to check if a key is in the disallowed list.
  isKeyAllowed = keyName: disallowedKeys: !builtins.elem keyName disallowedKeys;

  # Function to filter out disallowed keys from the list of all keys.
  filterAllowedKeys = allKeys: disallowedKeys:
    builtins.filter (key: isKeyAllowed key disallowedKeys) allKeys;

  # Function to map keys to their paths and trust levels.
  mapKeyPaths = keys: keyDir: trustMap: defaultTrust:
    builtins.map (keyName: {
      source = "${keyDir}/${keyName}";
      trust =
        if lib.hasAttr keyName trustMap
        then trustMap.${keyName}
        else defaultTrust;
    })
    keys;

  # Function to find keys listed in a list or map that are not present in the `keys` directory.
  findMissingKeys = keyList: builtins.filter (key: !builtins.elem key (getAllKeys keyDir)) keyList;

  # Create a set with missing keys for `disallowedKeys` and `keyTrustMap`.
  missingKeys = {
    disallowList = findMissingKeys cfg.disallowedKeys;
    trustMap = findMissingKeys (builtins.attrNames cfg.keyTrustMap);
  };
in {
  options.gpg = with lib; {
    enable = mkEnableOption "Enables GPG.";

    trustLevel = mkOption {
      default = "marginal";
      description = "Default trust level for unspecified keys.";
      type = with types;
        nullOr (enum [
          "unknown"
          "never"
          "marginal"
          "full"
          "ultimate"
        ]);
    };

    disallowedKeys = mkOption {
      default = [];
      description = "Keys that you don't wish to import.";
      type = with types; listOf str;
    };

    keyTrustMap = mkOption {
      default = {};
      description = "A map of keys to their specific trust levels.";
      type = with types;
        attrsOf (enum [
          "unknown"
          "never"
          "marginal"
          "full"
          "ultimate"
        ]);
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = builtins.concatLists [
      (
        if builtins.length missingKeys.disallowList > 0
        then [
          ''
            The following keys specified in `disallowedKeys` are not present in "${keyDir}":
            ${builtins.concatStringsSep "\n" (builtins.map (key: " - ${key}") missingKeys.disallowList)}
          ''
        ]
        else []
      )
      (
        if builtins.length missingKeys.trustMap > 0
        then [
          ''
            The following keys specified in `keyTrustMap` are not present in "${keyDir}":
            ${builtins.concatStringsSep "\n" (builtins.map (key: " - ${key}") missingKeys.trustMap)}
          ''
        ]
        else []
      )
    ];

    programs.gpg = {
      enable = true;

      mutableKeys = false;
      mutableTrust = false;

      # Read public keys from the `keys` directory, applying trust levels from the map or default.
      publicKeys =
        mapKeyPaths
        (filterAllowedKeys (getAllKeys keyDir) cfg.disallowedKeys)
        keyDir
        cfg.keyTrustMap
        cfg.trustLevel;

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
