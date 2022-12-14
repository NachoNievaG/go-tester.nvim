local M = {}

local ns = vim.api.nvim_create_namespace "live-tests"
local group = vim.api.nvim_create_augroup("go-tester", { clear = true })
local go_test_command = { "go", "test", "-v", "-json" }

M.setup = function(opts)
  if not opts then
    return
  end
  if opts.flags then
    for _, flag in pairs(opts.flags) do
      table.insert(go_test_command, flag)
    end
  end
end

function M.set_user_commands()
  local command = vim.api.nvim_create_user_command

  command("GoTestPackageOnSave", function()
    M.startPackageTest()
  end, {})

  command("GoTestFileOnSave", function()
    M.startFileTest()
  end, {})
end

local TSQuery = [[
(
 (function_declaration
  name: (identifier) @name
  parameters:
    (parameter_list
     (parameter_declaration
      name: (identifier)
      type: (pointer_type
          (qualified_type
           package: (package_identifier) @_package_name
           name: (type_identifier) @_type_name)))))

 (#eq? @_package_name "testing")
 (#eq? @_type_name "T")
 (#eq? @name "%s")
)
]]

local function redefine_augroup(bufnr)
  vim.diagnostic.reset(ns, bufnr)
  vim.api.nvim_del_augroup_by_id(group)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  group = vim.api.nvim_create_augroup("go-tester", { clear = true })
end

local function find_test_line(go_bufnr, name)
  local formatted = string.format(TSQuery, name)
  local query = vim.treesitter.parse_query("go", formatted)
  local parser = vim.treesitter.get_parser(go_bufnr, "go", {})
  local tree = parser:parse()[1]
  local root = tree:root()

  for id, node in query:iter_captures(root, go_bufnr, 0, -1) do
    if id == 1 then
      local range = { node:range() }
      return range[1]
    end
  end
end

local function isEmpty(s)
  return s == nil or s == ''
end

local function make_key(entry)
  assert(entry.Package, "Must have Package:" .. vim.inspect(entry))
  assert(entry.Test, "Must have Test:" .. vim.inspect(entry))
  return string.format("%s/%s", entry.Package, entry.Test)
end

local function handleTableTest(s)
  local fatherName = string.match(s, "(.+)[/]")
  if not isEmpty(fatherName) then
    return fatherName
  end
  return s
end

local function add_golang_test(state, entry)
  state.tests[make_key(entry)] = {
    name = entry.Test,
    line = find_test_line(state.bufnr, handleTableTest(entry.Test)),
    output = {},
  }
end

local function add_golang_output(state, entry)
  assert(state.tests, vim.inspect(state))
  table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
end

local function mark_success(state, entry)
  state.tests[make_key(entry)].success = entry.Action == "pass"
end

local function attach_to_buffer(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
  }
  redefine_augroup(bufnr)

  vim.api.nvim_buf_create_user_command(bufnr, "GoTestLineDiag", function()
    local line = vim.fn.line "." - 1
    for _, test in pairs(state.tests) do
      if test.line == line then
        vim.cmd.new()
        vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, test.output)
      end
    end
  end, {})

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.go",
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      state = {
        bufnr = bufnr,
        tests = {},
      }

      vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then
            return
          end

          for _, line in ipairs(data) do
            local decoded = vim.json.decode(line)
            if decoded.Action == "run" then
              add_golang_test(state, decoded)
            elseif decoded.Action == "output" then
              if not decoded.Test then
                return
              end

              add_golang_output(state, decoded)
            elseif decoded.Action == "pass" or decoded.Action == "fail" then
              mark_success(state, decoded)

              local test = state.tests[make_key(decoded)]
              if test.success then
                if test.line then
                  local text = { "???" }
                  vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, {
                    virt_text = { text },
                    end_line = 1,
                  })
                end
              end
            elseif decoded.Action == "pause" or decoded.Action == "cont" then
              -- Do nothing
            else
              error("Failed to handle" .. vim.inspect(data))
            end
          end
        end,

        on_exit = function()
          local failed = {}
          for _, test in pairs(state.tests) do
            if test.line then
              if not test.success then
                table.insert(failed, {
                  bufnr = bufnr,
                  lnum = test.line,
                  col = 0,
                  severity = vim.diagnostic.severity.ERROR,
                  source = "go-test",
                  message = "Test Failed: \n" .. '' .. table.concat(test.output, "\n"),
                  user_data = {},
                })
              end
            end
          end

          vim.diagnostic.set(ns, bufnr, failed, {})
        end,
      })
    end,
  })
  -- trigger the event the first time
  vim.api.nvim_exec_autocmds("BufWritePost", { group = group })
end

local function isValidTestFile(s)
  assert(string.find(s, "(.+_test.go)"), "current buffer is not a go test file", vim.inspect(s))
end

-- Scope the buffer's current package in the aucmd
function M.startPackageTest()
  local buf_path = vim.api.nvim_buf_get_name(0)
  isValidTestFile(buf_path)

  local route = string.match(buf_path, "(.+/)") .. "..."
  table.insert(go_test_command, route)

  attach_to_buffer(vim.api.nvim_get_current_buf(), go_test_command)
end

-- Scope only a file in the aucmd
function M.startFileTest()
  local buf_path = vim.api.nvim_buf_get_name(0)

  isValidTestFile(buf_path)
  table.insert(go_test_command, buf_path)

  attach_to_buffer(vim.api.nvim_get_current_buf(), go_test_command)
end

return M
