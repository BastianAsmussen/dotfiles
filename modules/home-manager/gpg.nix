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
  options.gpg = with lib; {
    enable = mkEnableOption "Enables GPG.";
    disallowedKeys = mkOption {
      default = [];
      description = "Keys that you don't wish to import.";
      type = with types; listOf str;
    };
  };

  config = lib.mkIf config.gpg.enable {
    assertions = [
      {
        assertion = builtins.all (key: builtins.pathExists "${keyDir}/${key}") config.gpg.disallowedKeys;
        message = ''Please ensure all disallowed keys are present in "${keyDir}"!'';
      }
    ];

    programs.gpg = {
      enable = true;

      # Read public keys from the `keys` directory.
      publicKeys = mapKeyPaths (filterAllowedKeys (getAllKeys keyDir) config.gpg.disallowedKeys) keyDir;
    };
  };
}
