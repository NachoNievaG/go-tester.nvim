if vim.g.loaded_go_tester then
  return
end
vim.g.loaded_go_tester = true

local command = vim.api.nvim_create_user_command

command("GoTestPackageOnSave", function()
  require("go-tester.suite").startPackageTest()
end, {})

command("GoTestFileOnSave", function()
  require("go-tester.suite").startFileTest()
end, {})
