{ inputs, ... }:
{
  # Copies one file out, so a closure never references the whole nix-secrets source.
  customLib.secrets.file =
    name:
    builtins.path {
      path = "${inputs.nix-secrets}/${name}";
      name = baseNameOf name;
    };
}
