{self, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    checks = {
      library = pkgs.callPackage ./_tests {
        inherit pkgs;
        inherit (self) lib;
      };

      # Check for dead Nix code.
      deadnix =
        pkgs.runCommandLocal "deadnix" {
          buildInputs = [pkgs.deadnix];
          src = ../.;
        } ''
          deadnix --fail "$src"
          touch $out
        '';

      # Lint Nix files.
      statix =
        pkgs.runCommandLocal "statix" {
          buildInputs = [pkgs.statix];
          src = ../.;
        } ''
          statix check "$src"
          touch $out
        '';

      # Check flake inputs.
      flake-checker =
        pkgs.runCommandLocal "flake-checker" {
          buildInputs = [pkgs.flake-checker];
          src = ../.;
        } ''
          flake-checker --fail-mode --no-telemetry "$src/flake.lock"
          touch $out
        '';

      # Validate unchecked flake outputs.
      output-theme = let
        base16Keys = ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"];
        hexOk = lib.all (k: builtins.match "^#[0-9A-Fa-f]{6}$" self.theme.${k} != null) base16Keys;
        noHashOk = lib.all (k: builtins.match "^[0-9A-Fa-f]{6}$" self.themeNoHash.${k} != null) base16Keys;
      in
        assert lib.assertMsg (lib.all (k: self.theme ? ${k}) base16Keys) "theme: not all base16 keys present";
        assert lib.assertMsg hexOk "theme: colors must be #RRGGBB hex";
        assert lib.assertMsg (lib.all (k: self.themeNoHash ? ${k}) base16Keys) "themeNoHash: not all base16 keys present";
        assert lib.assertMsg noHashOk "themeNoHash: colors must be RRGGBB hex (no # prefix)";
          pkgs.runCommandLocal "output-theme" {} "touch $out";

      output-lib = assert lib.assertMsg (self.lib ? custom) "lib: missing .custom";
      assert lib.assertMsg (self.lib.custom ? math) "lib.custom: missing .math";
      assert lib.assertMsg (self.lib.custom ? keys) "lib.custom: missing .keys";
      assert lib.assertMsg (self.lib.custom ? units) "lib.custom: missing .units";
        pkgs.runCommandLocal "output-lib" {} "touch $out";

      output-wrapperModules = assert lib.assertMsg (self.wrapperModules ? niri) "wrapperModules: missing .niri";
      assert lib.assertMsg (self.wrapperModules ? "which-key") "wrapperModules: missing .which-key";
        pkgs.runCommandLocal "output-wrapperModules" {} "touch $out";

      output-diskoConfigurations = assert lib.assertMsg (builtins.isAttrs self.diskoConfigurations) "diskoConfigurations: must be an attrset";
        pkgs.runCommandLocal "output-diskoConfigurations" {} "touch $out";

      output-topology = assert lib.assertMsg (builtins.isAttrs self.topology) "topology: must be an attrset";
        pkgs.runCommandLocal "output-topology" {} "touch $out";

      output-modules = assert lib.assertMsg (builtins.isAttrs self.modules) "modules: must be an attrset";
        pkgs.runCommandLocal "output-modules" {} "touch $out";

      output-mkWhichKeyExe = assert lib.assertMsg (builtins.isFunction self.mkWhichKeyExe) "mkWhichKeyExe: must be a function";
        pkgs.runCommandLocal "output-mkWhichKeyExe" {} "touch $out";

      output-preferences = assert lib.assertMsg (builtins.isAttrs self.preferences) "preferences: must be an attrset";
      assert lib.assertMsg (self.preferences ? name) "preferences: missing .name";
      assert lib.assertMsg (self.preferences ? "full-name") "preferences: missing .full-name";
      assert lib.assertMsg (self.preferences ? email) "preferences: missing .email";
        pkgs.runCommandLocal "output-preferences" {} "touch $out";
    };
  };
}
