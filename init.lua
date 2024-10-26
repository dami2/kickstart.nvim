--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================

Kickstart.nvim is *not* a distribution.

Kickstart.nvim is a template for your own configuration.
  The goal is that you can read every line of code, top-to-bottom, understand
  what your configuration is doing, and modify it to suit your needs.

  Once you've done that, you should start exploring, configuring and tinkering to
  explore Neovim!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example:
  - https://learnxinyminutes.com/docs/lua/


  And then you can explore or search through `:help lua-guide`
  - https://neovim.io/doc/user/lua-guide.html


Kickstart Guide:

I have left several `:help X` comments throughout the init.lua
You should run that command and read that help section for more information.

In addition, I have some `NOTE:` items throughout the file.
These are for you, the reader to help understand what is happening. Feel free to delete
them once you know what you're doing, but they should serve as a guide for when you
are first encountering a few different constructs in your nvim config.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now :)
--]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)

-- Global function to blink on search
function Blink_highlight_search(blinktime)
  local ns = vim.api.nvim_create_namespace("search")
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local search_pat = "\\c\\%#" .. vim.fn.getreg("/")
  local m = vim.fn.matchadd("IncSearch", search_pat)
  vim.cmd("redraw")
  vim.cmd("sleep " .. blinktime * 1000 .. "m")

  local sc = vim.fn.searchcount()
  vim.api.nvim_buf_set_extmark(0, ns, vim.api.nvim_win_get_cursor(0)[1] - 1, 0, {
    virt_text = { { "[" .. sc.current .. "/" .. sc.total .. "]", "Comment" } },
    virt_text_pos = "eol",
  })

  vim.fn.matchdelete(m)
  vim.cmd("redraw")
end

-- Utility function to setup lualine
local function setup_lualine()
  require('lualine').setup({
    options = {
      icons_enabled = false,
      theme = 'dracula-nvim',
      component_separators = '|',
      section_separators = '',
    },
    sections = {
      -- lualine_a = { 'mode' },
      lualine_b = { 'filename', 'diagnostics' },
      lualine_c = { 'location', 'progress' },
      lualine_x = { 'diff', 'branch' },
      lualine_y = { 'encoding', 'fileformat', },
      lualine_z = { 'filetype' }
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { { 'filename', path = 1 } },
      lualine_x = { 'location' },
      lualine_y = {},
      lualine_z = {}
    },
  })
end

-- Utility function to setup indent blank line (ibl)
local function setup_ibl()
  require("ibl").setup({
    indent = { char = '┊' }
  })
end

-- Utility function to re-setup ibl only if is enabled
local function setup_ibl_if_is_enabled()
  if require('ibl').initialized then
    setup_ibl()
  end
end

-- Utility function to print map values
-- use it with print(Dump(some_map))
-- read it with :messages
function Dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k, v in pairs(o) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. Dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- Utility function to disconnect yamlls for helm charts
-- The main idea here is to do a quick pattern check on the yaml file, {{.+}}.
-- If the pattern match is true then we wait an arbitrary amount of time (500 ms seems to work well for me) and detach the yamlls from the buffer.
local function detach_yamlls()
  local clients = vim.lsp.get_active_clients()
  for client_id, client in pairs(clients) do
    if client.name == "yamlls" then
      vim.lsp.buf_detach_client(0, client_id)
      -- vim.cmd("LspStop ".. client.id)
      vim.cmd "set syntax=helm"
    end
  end
end

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable display of hidden characters (spaces, tabs, end-of-line)
-- vim.opt.list = true
-- -- Customize list characters
-- vim.opt.listchars:append({ space = '.', tab = '>-', eol = '$' })

-- disable netrwPlugin
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.
require('lazy').setup({
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',
  -- Disable default GitHub plugin
  -- 'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      {
        'williamboman/mason.nvim',
        opts = {
          ui = {
            -- a number <1 is a percentage., >1 is a fixed size
            width = 0.99,
          },
          ensure_installed = {
            "typescript-language-server",
            "eslint-lsp",
            "yaml-language-server",
            "json-lsp",
            "prettier",
            "pyright",
            "rust-analyzer",
            "denols"
          }
        }
      },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',

      -- Adds source for buffer words
      'hrsh7th/cmp-buffer'
    }
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim',  opts = {} },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })

        -- don't override the built-in and fugitive keymaps
        local gs = package.loaded.gitsigns
        vim.keymap.set({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
        vim.keymap.set({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
        vim.keymap.set('n', '<leader>tgb', require('gitsigns').toggle_current_line_blame,
          { buffer = bufnr, desc = '[T]oggle [G]it [B]lame' })
        vim.keymap.set('n', '<leader>rh', require('gitsigns').reset_hunk, { buffer = bufnr, desc = '[R]eset [H]uk' })
        vim.keymap.set('n', '<leader>gsh', require('gitsigns').stage_hunk,
          { buffer = bufnr, desc = '[G]it [S]tage [H]uk' })
      end,
    },
  },

  -- {
  --   -- Theme inspired by Atom
  --   'navarasu/onedark.nvim',
  --   priority = 1000,
  --   config = function()
  --     vim.cmd.colorscheme 'onedark'
  --   end,
  -- },

  'Haron-Prime/Antares',
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha"
    }
  },
  {
    'Mofiqul/dracula.nvim',
    priority = 1000,
    opts = {
      theme = 'dracula-soft',
      colors = {
        bg = '#303030',
      },
      overrides = function(colors)
        return {
          Search = { fg = colors.black, bg = colors.cyan, },
        }
      end,
    },
    config = function(_, opts)
      require("dracula").setup(opts)
      vim.cmd.colorscheme 'dracula-soft'
      vim.cmd('hi Cursorline guibg=#404355')
      setup_lualine()
      setup_ibl_if_is_enabled()
    end,
  },
  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    setup = setup_lualine
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    setup = setup_ibl,
    keys = {
      { "<leader>ti", "<CMD>IBLToggle<CR>", desc = "[ti] Toggle ident-blankline" },
    },
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    build = ':TSUpdate',
  },

  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  -- { import = 'custom.plugins' },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },

  -- Better quickfix window in Neovim
  {
    "kevinhwang91/nvim-bqf",
    event = "VeryLazy",
    opt = {}
  },

  {
    "towolf/vim-helm",
    -- event = "VeryLazy",
    lazy = false,
    opt = {}
  },

  {
    'stevearc/oil.nvim',
    lazy = false,
    opts = {
      default_file_explorer = true,
      -- columns = {
      --   -- "icon",
      --   "permissions",
      --   "size",
      --   "mtime",
      -- },
      keymaps = {
        ["."] = "actions.cd",
      },
    },
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    -- Optional dependencies
    -- dependencies = { "nvim-tree/nvim-web-devicons" },
  },

  {
    'tpope/vim-abolish'
  },

  {
    'bkad/CamelCaseMotion',
    init = function()
      vim.g.camelcasemotion_key = '<leader>'
    end
  },

  {
    'prettier/vim-prettier'
  },

  {
    'github/copilot.vim'
  },

  -- {
  --   'chr4/nginx.vim'
  -- }
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = {},
    event = "VeryLazy",
  },

  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {
      startVisible = true,
      showBlankVirtLine = false,
      -- highlightColor = { link = "Comment" },
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     G = { text = "G", prio = 10 },
      --     gg = { text = "gg", prio = 9 },
      --     PrevParagraph = { text = "{", prio = 8 },
      --     NextParagraph = { text = "}", prio = 8 },
      -- },
    },
  }
}, {})

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Set blinking cursor
vim.o.guicursor = 'a:blinkon100'

-- Disable default line numbers
-- vim.wo.number = false

-- Highlight the current line number
vim.opt.cursorline = true
-- -- Enable hybrid line numbers
vim.cmd("set number relativenumber")

-- Enable mouse mode
vim.o.mouse = ''

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Toggle line numbers
vim.keymap.set('n', '<leader>tn', '<cmd>set invnumber<cr>', { desc = '[ti] Toggle line numbers' })
-- Toggle relative line numbers
vim.keymap.set('n', '<leader>tr', '<cmd>set invrelativenumber<cr>', { desc = '[ti] Toggle relatie line numbers' })

-- Toggle quickfix
vim.keymap.set('n', '<leader>tq', function()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists == true then
    vim.cmd "cclose"
    return
  end
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd "copen"
  end
end, { desc = '[tq] Toggle [Q]uickfix list' })

--- Mappings for buffers
vim.keymap.set('n', '<leader>bca', '<cmd>bufdo bdelete<cr>', { desc = '[B]uffers [C]lose [A]ll' })
vim.keymap.set('n', '<leader>bco', '<cmd>%bd|e#<cr>', { desc = '[B]uffers [C]lose [O]thers' })

-- Mappigs for yank to clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = '[y] Yank to clipboard' })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = '[Y] Yank line to clipboard' })

-- Keep cursor in position after joining lines
vim.keymap.set("n", "J", "mzJ`z")

-- Center view after moving
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center view after search and blink
vim.keymap.set("n", "n", "nzzzv<cmd>lua Blink_highlight_search(0.3)<cr>")
vim.keymap.set("n", "N", "Nzzzv<cmd>lua Blink_highlight_search(0.3)<cr>")

-- Move selected lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Center view on Quick and Location list commands
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = '[k] Next location list' })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = '[j] Prev location list' })

-- Widow arrangement
vim.keymap.set("n", "<leader>wh", "<cmd>windo wincmd K<cr>", { desc = 'Arrange [W]indows [H]orizontaly' })
vim.keymap.set("n", "<leader>wv", "<cmd>windo wincmd H<cr>", { desc = 'Arrange [W]indows [V]erticaly' })

-- Copy current buffer file path to clipboard
vim.keymap.set("n", "<leader>cpr", '<cmd>let @+=expand("%")<cr>', { desc = '[C]opy buffer [R]elative file [P]ath' })
vim.keymap.set("n", "<leader>cpa", '<cmd>let @+=expand("%:p")<cr>', { desc = '[C]opy buffer [A]bsolute file [P]ath' })
vim.keymap.set("n", "<leader>cpf", '<cmd>let @+=expand("%:t")<cr>', { desc = '[C]opy buffer [F]ile name [P]ath' })
vim.keymap.set("n", "<leader>cpd", '<cmd>let @+=expand("%:p:h")<cr>', { desc = '[C]opy buffer [D]ir name [P]ath' })

-- Esc leaves the terminal

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = 'Escape terminal' })
--auto close mappings
-- Double quotes
-- vim.api.nvim_set_keymap('i', '"', '""<left>', { noremap = true })
--
-- -- Single quotes
-- vim.api.nvim_set_keymap('i', "'", "''<left>", { noremap = true })
--
-- -- Parentheses
-- vim.api.nvim_set_keymap('i', '(', '()<left>', { noremap = true })
--
-- -- Square brackets
-- vim.api.nvim_set_keymap('i', '[', '[]<left>', { noremap = true })
--
-- -- Curly braces
-- vim.api.nvim_set_keymap('i', '{', '{}<left>', { noremap = true })
--
-- -- Curly braces with Enter
-- vim.api.nvim_set_keymap('i', '{<CR>', '{<CR>}<ESC>O', { noremap = true })
--
-- -- Curly braces with semicolon and Enter
-- vim.api.nvim_set_keymap('i', '{;<CR>', '{<CR>};<ESC>O', { noremap = true })

-- Clear highlight search
vim.keymap.set('n', '<Esc>', '<cmd>noh<cr>', { desc = 'Clear highlights' })

-- Copilot mappings
-- vim.keymap.set('i', '<C-J>', 'copilot#Accept("<CR>")', {
--   expr = true,
--   replace_keycodes = false
-- })

vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false
})
vim.g.copilot_no_tab_map = true
vim.g.copilot_enabled = true

-- Map Caps Lock to Escape in Neovim
vim.api.nvim_set_keymap('n', '<CapsLock>', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<CapsLock>', '<Esc>', { noremap = true, silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
local action_layout = require("telescope.actions.layout")
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
        ["<C-l>"] = action_layout.toggle_preview,
        ["<CR>"] = require("telescope.actions").select_default + require("telescope.actions").center -- center view after selection
      },
      n = {
        ["<CR>"] = require("telescope.actions").select_default + require("telescope.actions").center, -- center view after selection
        ["<C-l>"] = action_layout.toggle_preview
      },
    },
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        height = { padding = 0 },
        width = { padding = 0 }
      }
    },
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', function()
  require('telescope.builtin').live_grep({
    disable_coordinates = true
  })
end, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', function()
  require('telescope.builtin').diagnostics { no_sign = false }
end
, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>sm', require('telescope.builtin').git_commits, { desc = '[S]earch co[M]mits' })
vim.keymap.set('n', '<leader>so', require('telescope.builtin').git_bcommits, { desc = '[S]earch buffer C[o]mmits' })
vim.keymap.set('n', '<leader>su', require('telescope.builtin').git_status, { desc = '[S]earch Git Stat[U]s' })
vim.keymap.set('n', '<leader>st', require('telescope.builtin').git_stash, { desc = '[S]earch git s[T]ash' })
vim.keymap.set('n', '<leader>sc', require('telescope.builtin').commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader>sb', require('telescope.builtin').buffers, { desc = '[S]earch [B]uffers' })

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'json', 'vimdoc', 'vim', 'bash' },

    -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
    auto_install = false,

    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    },
  }
end, 0)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', function()
    require('telescope.builtin').lsp_references({ show_line = false, file_ignore_patterns = { "%.spec.*" } })
  end, '[G]oto [R]eferences excluding tests')
  nmap('<leader>gr', function()
    require('telescope.builtin').lsp_references { show_line = false }
  end, '[G]oto [R]eferences including tests')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-l>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })

  nmap('<leader>F', '<cmd>Format<cr>', '[F]ormat')

  nmap('<leader>tl', function()
    local original_bufnr = vim.api.nvim_get_current_buf()
    local buf_clients = vim.lsp.get_active_clients { bufnr = original_bufnr }

    if buf_clients[1] == nil then
      vim.cmd('LspStart')
    else
      vim.cmd('LspStop')
    end
  end, '[tl] Toggle LSP')
end

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- rust_analyzer = {},
  pyright = { filetypes = { "python" } },
  rust_analyzer = {},
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },
  helm_ls = {},
  yamlls = {},
  sqlls = { filetypes = { 'sql' } },
  -- nginx_language_server = {},
  zls = {},

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  -- The first entry (without a key) will be the default handler
  -- and will be called for each installed server that doesn't have
  -- a dedicated handler.
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
  -- Next, you can provide a dedicated handler for specific servers.
  -- For example, a handler override for the `helm_ls`:
  ["helm_ls"] = function()
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    lspconfig.helm_ls.setup {
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { "helm_ls", "serve" },
      filetypes = { 'helm', 'yaml', 'yml' },
      root_dir = function(fname)
        return util.root_pattern('Chart.yaml')(fname)
      end,
    }
  end,
  ["sqlls"] = function()
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    lspconfig.sqlls.setup {
      capabilities = capabilities,
      on_attach = on_attach,
      cmd = { "sql-language-server", "up", "--method", "stdio" },
      filetypes = { "sql" },
      -- root_dir = lspconfig.util.root_pattern(".git", vim.fn.getcwd()),
      root_dir = function(fname)
        return util.root_pattern(".git", vim.fn.getcwd())(fname)
      end,
    }
  end,
  ["eslint"] = function()
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    lspconfig.eslint.setup {
      capabilities = capabilities,
      on_attach = on_attach,
      root_dir = function(fname)
        return util.root_pattern(".git", vim.fn.getcwd())(fname)
      end,
    }
  end,
  -- ["nginx_language_server"] = function()
  --   local lspconfig = require('lspconfig')
  --   local util = require('lspconfig.util')
  --
  --   lspconfig.nginx_language_server.setup {
  --     capabilities = capabilities,
  --     on_attach = on_attach,
  --     cmd = { 'nginx-language-server' },
  --     filetypes = { 'nginx' },
  --     root_dir = function(fname)
  --       return util.root_pattern('*.conf', '.git') or util.find_git_ancestor(fname)
  --     end,
  --     single_file_support = true,
  --   }
  -- end,
  ["denols"] = function()
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    lspconfig.denols.setup {
      capabilities = capabilities,
      on_attach = on_attach,
      root_dir = util.root_pattern("deno.json", "deno.jsonc")
    }
  end,
  ["tsserver"] = function()
    local lspconfig = require('lspconfig')
    local util = require('lspconfig.util')

    lspconfig.tsserver.setup {
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- Optionally disable tsserver in Deno projects
        if util.root_pattern("deno.json", "deno.jsonc")(vim.fn.getcwd()) then
          client.stop() -- Stop tsserver in Deno projects
        else
          on_attach(client, bufnr)
        end
      end,
      root_dir = util.root_pattern("package.json"), -- Only attach to Node.js projects
    }
  end,
}

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    {
      name = 'buffer',
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end
      }
    }
  },
  experimental = {
    ghost_text = false -- this feature conflict with copilot.vim's preview.
  }
}

-- Autocommand for toggling colorscheme on mode change
-- local mode_feed_back_group = vim.api.nvim_create_augroup('ModeFeedBack', { clear = true })
-- vim.api.nvim_create_autocmd('InsertEnter', {
--   callback = function()
--     vim.cmd.colorscheme 'catppuccin'
--     -- vim.cmd('hi Cursorline guibg=#212121')
--     setup_lualine()
--     setup_ibl_if_is_enabled()
--   end,
--   group = mode_feed_back_group,
--   pattern = '*',
-- })
-- vim.api.nvim_create_autocmd('InsertLeave', {
--   callback = function()
--     vim.cmd.colorscheme 'dracula-soft'
--     vim.cmd('hi Cursorline guibg=#404355')
--     setup_lualine()
--     setup_ibl_if_is_enabled()
--   end,
--   group = mode_feed_back_group,
--   pattern = '*',
-- })
--
vim.api.nvim_exec([[
  augroup InsertModeColors
    autocmd!
    autocmd InsertEnter * hi Normal guibg=#191A21 ctermbg=black
    autocmd InsertLeave * hi Normal guibg=#303030 ctermbg=NONE
  augroup END
]], false)

function create_augroup(autocmds, name)
  vim.api.nvim_command('augroup ' .. name)
  vim.api.nvim_command('autocmd!')
  for _, autocmd in ipairs(autocmds) do
    local cmd = table.concat(vim.tbl_flatten { 'autocmd', autocmd }, ' ')
    vim.api.nvim_command(cmd)
  end
  vim.api.nvim_command('augroup END')
end

-- Change cursor shape to a block in insert mode
create_augroup({
  { 'InsertEnter', '*', 'set guicursor=a:ver25' },
  { 'InsertLeave', '*', 'set guicursor=a:blinkon100' }

}, 'change_cursor_shape')

local gotmpl_group = vim.api.nvim_create_augroup("_gotmpl", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = gotmpl_group,
  pattern = "yaml",
  callback = function()
    vim.schedule(function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for _, line in ipairs(lines) do
        if string.match(line, "{{.+}}") then
          vim.defer_fn(detach_yamlls, 500)
          return
        end
      end
    end)
  end,
})

-- Custom command for js/ts imports
vim.api.nvim_create_user_command('OrganizeImports', function()
  local params = {
    command = "_typescript.organizeImports",
    arguments = { vim.api.nvim_buf_get_name(0) }
  }
  vim.lsp.buf.execute_command(params)
end, { desc = "Organize javascript imports" })

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
