-- 1. Register plugins using vim.pack
vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/olimorris/codecompanion.nvim',
}

-- 2. Configure CodeCompanion for local Ollama
require('codecompanion').setup {
  interactions = {
    chat = { adapter = 'ollama' },
    inline = { adapter = 'ollama' },
  },
  adapters = {
    http = {
      ollama = function()
        return require('codecompanion.adapters').extend('ollama', {
          schema = {
            model = {
              default = 'qwen2.5-coder:1.5b',
            },
          },
        })
      end,
    },
  },
}

-- 3. Set keymaps
local keymap = vim.keymap.set
keymap({ 'n', 'v' }, '<leader>aa', '<cmd>CodeCompanionActions<cr>', { desc = '[A]I [A]ctions' })
keymap({ 'n', 'v' }, '<leader>ac', '<cmd>CodeCompanionChat Toggle<cr>', { desc = '[A]I [C]hat' })
keymap('v', '<leader>ai', ':<C-u>CodeCompanion ', { desc = '[A]I [I]nline Edit' })

vim.cmd [[cab cc CodeCompanion]]
