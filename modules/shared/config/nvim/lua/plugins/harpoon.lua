local function toggle_telescope()
  local harpoon = require 'harpoon'
  local conf = require('telescope.config').values
  local file_paths = {}
  for _, item in ipairs(harpoon:list().items) do
    table.insert(file_paths, item.value)
  end
  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Harpoon',
      finder = require('telescope.finders').new_table { results = file_paths },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
  keys = {
    { '<leader>a', function() require('harpoon'):list():add() end, desc = 'Harpoon [a]dd file' },
    { '<C-e>', toggle_telescope, desc = 'Harpoon quick menu' },
    { '<leader>1', function() require('harpoon'):list():select(1) end, desc = 'Harpoon file [1]' },
    { '<leader>2', function() require('harpoon'):list():select(2) end, desc = 'Harpoon file [2]' },
    { '<leader>3', function() require('harpoon'):list():select(3) end, desc = 'Harpoon file [3]' },
    { '<leader>4', function() require('harpoon'):list():select(4) end, desc = 'Harpoon file [4]' },
  },
  config = function()
    require('harpoon'):setup()
  end,
}
