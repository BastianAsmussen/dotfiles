return {
  {
    {
      'mrcjkb/rustaceanvim',
      version = '^4', -- Recommended
      lazy = false, -- This plugin is already lazy
    },
    {
      'saecki/crates.nvim',
      ft = { "rust", "toml" },
      config = function(_, opts)
        local crates = require('crates')
        crates.setup(opts)
        crates.show()
      end,
    },
  },
}
