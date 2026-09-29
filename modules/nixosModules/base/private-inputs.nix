{ config, ... }:
{
  flake.nixosModules.base = {
    warnings = map (
      hit: "Private flake input read from its source; use its outputs instead: ${hit}"
    ) config.customLib.privateInputAccess;
  };
}
