{
  # Autocommands and their groups.
  flake.nixvimModules.autocmds = {
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

        # Undo files would write /dev/shm secrets to the persisted state dir.
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

            -- shada is global and stores registers, including yanked secrets.
            vim.o.shadafile = "NONE"
          end
        '';
      }
    ];
  };
}
