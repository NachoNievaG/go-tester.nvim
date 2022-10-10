local ok, suite = pcall(require, "tester.suite")
if not ok then return end

vim.g.loaded_go_tester = true
return suite
