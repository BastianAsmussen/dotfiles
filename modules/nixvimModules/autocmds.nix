{
  # Autocommands and their groups.
  flake.nixvimModules.autocmds =
    { ... }:
    {
      autoGroups = {
        highlight-yank.clear = true;
        secret-buffers.clear = true;
      };

      autoCmd = [
        {
          event = [ "TextYankPost" ];
          desc = "Highlight when yanking (copying) text";
          group = "highlight-yank";
          callback.__raw = ''
            function()
              vim.highlight.on_yank({ higroup = "IncSearch", timeout = 100 })
            end
          '';
        }
        {
          event = [
            "BufReadPre"
            "BufNewFile"
          ];

          # gopass and pass edit secrets under /dev/shm precisely so the
          # plaintext never reaches a disk. undofile wrote it out anyway, and on
          # the impermanent hosts ~/.local/state/nvim is bind-mounted from
          # /persist, so those undo files survived every reboot.
          pattern = [
            "/dev/shm/*"
            "/dev/shm/**"
            "/tmp/*"
            "/tmp/**"
            "*/.password-store/*"
            "*.gpg"
            "*.asc"
          ];

          desc = "Never persist undo, swap or shada for secret files";
          group = "secret-buffers";
          callback.__raw = ''
            function()
              vim.opt_local.undofile = false
              vim.opt_local.swapfile = false
              vim.opt_local.backup = false
              vim.opt_local.writebackup = false

              -- shada has no buffer-local form, and it stores register
              -- contents: one yank out of a secret would land in it. Disabling
              -- it costs this session its marks and command history, which is
              -- the cheaper half of the trade.
              vim.o.shadafile = "NONE"
            end
          '';
        }
      ];
    };
}
