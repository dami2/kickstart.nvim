return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {
      enabled = true,
      debounce = 500,
      indent = { char = '┊' },
    },
    -- keys = {
    --   { '<leader>ti', '<CMD>IBLToggle<CR>', desc = '[ti] Toggle ident-blankline' },
    -- },
  },
}
