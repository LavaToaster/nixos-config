return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VimEnter',
  keys = {
    { '<Tab>', '<cmd>BufferLineCycleNext<CR>', desc = 'Next buffer' },
    { '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', desc = 'Previous buffer' },
    { '<leader>x', '<cmd>bdelete<CR>', desc = 'Close buffer' },
  },
  opts = {
    options = {
      diagnostics = 'nvim_lsp',
      offsets = {
        { filetype = 'neo-tree', text = 'File Explorer', highlight = 'Directory', separator = true },
      },
    },
  },
}
