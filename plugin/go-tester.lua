if vim.g.loaded_go_tester then
  return
end

require('go-tester').setup()
vim.g.loaded_go_tester = true
