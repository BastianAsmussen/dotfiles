{ inputs, ... }:
{
  flake.nixvimModules.micro-harness = {
    imports = [ inputs.micro-harness-nvim.nixvimModules.default ];

    plugins.micro-harness.enable = true;
  };
}
