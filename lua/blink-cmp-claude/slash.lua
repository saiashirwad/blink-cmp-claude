local M = {}

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  local config = require('blink-cmp-claude').config
  self.filetype = config.filetype
  self.commands = require('blink-cmp-claude.discovery').get_all_commands(config)
  return self
end

function M:enabled()
  return vim.bo.filetype == self.filetype
end

function M:get_trigger_characters()
  return { '/' }
end

function M:get_completions(context, callback)
  local line = context.line
  local col = context.cursor[2]
  local before = line:sub(1, col - 1)

  if not before:match('^%s*$') then
    callback({ items = {}, is_incomplete_forward = false })
    return
  end

  local items = {}
  for _, cmd in ipairs(self.commands) do
    local label = '/' .. cmd.name
    if cmd.hint then
      label = label .. ' ' .. cmd.hint
    end
    table.insert(items, {
      label = label,
      kind = vim.lsp.protocol.CompletionItemKind.Keyword,
      documentation = cmd.desc,
      insertText = '/' .. cmd.name .. ' ',
      filterText = '/' .. cmd.name,
    })
  end

  callback({ items = items, is_incomplete_forward = false })
end

return M
