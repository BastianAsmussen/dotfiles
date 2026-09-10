{
  # OSC 52 clipboard, so yanks reach the host over SSH.
  flake.nixvimModules.clipboard =
    { ... }:
    {
      extraConfigLuaPost = ''
        if os.getenv("SSH_TTY") or os.getenv("SSH_CONNECTION") then
          vim.g.clipboard = {
            name = "OSC 52",
            copy = {
              ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
              ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
            },
            paste = {
              ["+"] = require('vim.ui.clipboard.osc52').paste("+"),
              ["*"] = require('vim.ui.clipboard.osc52').paste("*"),
            },
          }
        end
      '';
    };
}
