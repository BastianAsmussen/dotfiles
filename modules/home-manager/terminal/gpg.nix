{
  lib,
  config,
  osConfig,
  ...
}: let
  inherit (builtins) attrNames readDir elem filter concatLists length concatStringsSep;
  inherit (lib) hasAttr mkEnableOption mkOption types mkIf;

  cfg = config.gpg;

  keyDir = ../../../keys;
  # Function to get all key names in the specified directory.
  getAllKeys = keyDir: attrNames (readDir keyDir);
  # Function to check if a key is in the disallowed list.
  isKeyAllowed = keyName: disallowedKeys: !elem keyName disallowedKeys;
  # Function to filter out disallowed keys from the list of all keys.
  filterAllowedKeys = allKeys: disallowedKeys:
    filter (key: isKeyAllowed key disallowedKeys) allKeys;
  # Function to map keys to their paths and trust levels.
  mapKeyPaths = keys: keyDir: trustMap: defaultTrust:
    map (keyName: {
      source = "${keyDir}/${keyName}";
      trust =
        if hasAttr keyName trustMap
        then trustMap.${keyName}
        else defaultTrust;
    })
    keys;

  # Function to find keys listed in a list or map that are not present in the `keys` directory.
  findMissingKeys = filter (key: !elem key (getAllKeys keyDir));
  # Create a set with missing keys for `disallowedKeys` and `keyTrustMap`.
  missingKeys = {
    disallowList = findMissingKeys cfg.disallowedKeys;
    trustMap = findMissingKeys (attrNames cfg.keyTrustMap);
  };
in {
  options.gpg = {
    enable = mkEnableOption "Enables GPG.";

    trustLevel = mkOption {
      default = "marginal";
      description = "Default trust level for unspecified keys.";
      type = types.nullOr (types.enum [
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
      type = types.listOf types.str;
    };

    keyTrustMap = mkOption {
      default = {};
      description = "A map of keys to their specific trust levels.";
      type = types.attrsOf (types.enum [
        "unknown"
        "never"
        "marginal"
        "full"
        "ultimate"
      ]);
    };
  };

  config = mkIf cfg.enable {
    warnings = concatLists [
      (
        if length missingKeys.disallowList > 0
        then [
          ''
            The following keys specified in `disallowedKeys` are not present in "${keyDir}":
            ${concatStringsSep "\n" (map (key: " - ${key}") missingKeys.disallowList)}
          ''
        ]
        else []
      )
      (
        if length missingKeys.trustMap > 0
        then [
          ''
            The following keys specified in `keyTrustMap` are not present in "${keyDir}":
            ${concatStringsSep "\n" (map (key: " - ${key}") missingKeys.trustMap)}
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

      scdaemonSettings.disable-ccid = osConfig.yubiKey.enable; # Disable CCID conflicts when using a YubiKey.
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
