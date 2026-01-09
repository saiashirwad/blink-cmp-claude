local M = {}

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  local config = require('blink-cmp-claude').config
  self.filetype = config.filetype
  return self
end

function M:enabled()
  return vim.bo.filetype == self.filetype
end

function M:get_trigger_characters()
  return { '@' }
end

function M:get_completions(context, callback)
  local line = context.line
  local col = context.cursor[2]
  local before = line:sub(1, col)

  local at_match = before:match('@([^@%s]*)$')
  if not at_match then
    callback({ items = {}, is_incomplete_forward = false })
    return
  end

  local cwd = vim.fn.getcwd()
  local pattern = cwd .. '/' .. at_match .. '*'
  local matches = vim.fn.glob(pattern, false, true)

  local items = {}
  for _, path in ipairs(matches) do
    local rel = path:sub(#cwd + 2)
    local is_dir = vim.fn.isdirectory(path) == 1
    table.insert(items, {
      label = '@' .. rel,
      kind = is_dir and vim.lsp.protocol.CompletionItemKind.Folder or vim.lsp.protocol.CompletionItemKind.File,
      insertText = '@' .. rel .. (is_dir and '/' or ' '),
      filterText = '@' .. rel,
    })
  end

  callback({ items = items, is_incomplete_forward = #matches > 50 })
end

return M
