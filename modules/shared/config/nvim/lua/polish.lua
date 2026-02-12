-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE


-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
--

return {
  mappings = {
    v = {
      -- Prevent visual selection from automatically yanking
      ["<leader>y"] = { '"+y', desc = "Yank to clipboard" },
    },
  },
  options = {
    opt = {
      clipboard = "unnamedplus", -- Keep clipboard integration
    },
  },
}
