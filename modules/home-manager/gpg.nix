{
  lib,
  config,
  ...
}: let
  keyDir = ../../keys;

  getAllKeys = keyDir: builtins.attrNames (builtins.readDir keyDir);
  isKeyAllowed = keyName: disallowedKeys: builtins.elem keyName disallowedKeys;
  filterAllowedKeys = allKeys: disallowedKeys: builtins.filter (key: !isKeyAllowed key disallowedKeys) allKeys;
  mapKeyPaths = keys: keyDir: builtins.map (keyName: {source = "${keyDir}/${keyName}";}) keys;

  findMissingKeys = keys: builtins.filter (key: !builtins.elem key (getAllKeys keyDir)) keys;
  missingKeys = findMissingKeys config.gpg.disallowedKeys;
in {
  options.gpg = with lib; {
    enable = mkEnableOption "Enables GPG.";
    disallowedKeys = mkOption {
      default = [];
      description = "Keys that you don't wish to import.";
      type = with types; listOf str;
    };
  };

  config = lib.mkIf config.gpg.enable {
    warnings =
      if builtins.length missingKeys > 0
      then [
        ''
          The following keys specified in disallowedKeys are not present in "${keyDir}":
          ${builtins.concatStringsSep "\n" (builtins.map (key: " - ${key}") missingKeys)}
        ''
      ]
      else [];

    programs.gpg = {
      enable = true;

      # Read public keys from the `keys` directory.
      publicKeys = mapKeyPaths (filterAllowedKeys (getAllKeys keyDir) config.gpg.disallowedKeys) keyDir;
    };
  };
}
