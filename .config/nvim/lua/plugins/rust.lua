return {
  {
    {
      'mrcjkb/rustaceanvim',
      version = '^4', -- Recommended.
      lazy = false, -- This plugin is already lazy.
    },
    {
      'rust-lang/rust.vim',
      ft = 'rust',
      init = function()
        vim.g.rustfmt_autosave = 1
      end
    },
    {
      'saecki/crates.nvim',
      ft = { 'rust', 'toml' },
      config = function(_, opts)
        local crates = require('crates')
        crates.setup(opts)
        crates.show()
      end,
    },
  },
}
