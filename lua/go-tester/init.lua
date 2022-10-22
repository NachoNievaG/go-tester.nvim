local ok, suite = pcall(require, "go-tester.suite")
if not ok then return end

local Go_tester = {}

function Go_tester.setup(options)
  suite.setup(options)
  suite.set_user_commands()
end

vim.g.loaded_go_tester = true
return Go_tester
