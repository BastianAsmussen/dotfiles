{inputs, ...}: {
  flake.lib = inputs.nixpkgs.lib.extend (final: _prev: {
    custom = import ./_lib final;
  });
}
