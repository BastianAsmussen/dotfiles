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
in {
  options.gpg = {
    enable = lib.mkEnableOption "Enables GPG.";
    disallowedKeys = lib.mkOption {
      default = [];
      description = "Keys that you don't wish to import.";
      type = with lib.types; listOf str;
    };
  };

  config = lib.mkIf config.gpg.enable {
    programs.gpg = {
      enable = true;

      # Read public keys from the `keys` directory.
      publicKeys = mapKeyPaths (filterAllowedKeys (getAllKeys keyDir) config.gpg.disallowedKeys) keyDir;
    };
  };
}
