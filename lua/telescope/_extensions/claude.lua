local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

local function get_workspace_symbols(query)
  local params = { query = query or '' }
  local results = vim.lsp.buf_request_sync(0, 'workspace/symbol', params, 5000)

  local symbols = {}
  for _, res in pairs(results or {}) do
    for _, symbol in ipairs(res.result or {}) do
      local loc = symbol.location
      local range = loc.range
      table.insert(symbols, {
        name = symbol.name,
        kind = vim.lsp.protocol.SymbolKind[symbol.kind] or 'Unknown',
        file = vim.uri_to_fname(loc.uri),
        start_line = range.start.line + 1,
        end_line = range['end'].line + 1,
        container = symbol.containerName,
      })
    end
  end
  return symbols
end

local function symbols_picker(opts)
  opts = opts or {}
  local symbols = get_workspace_symbols(opts.query)

  if #symbols == 0 then
    vim.notify('No symbols found (is LSP running?)', vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = 'Claude: Insert @symbol',
    finder = finders.new_table({
      results = symbols,
      entry_maker = function(entry)
        local rel = vim.fn.fnamemodify(entry.file, ':~:.')
        local container = entry.container and (entry.container .. '.') or ''
        return {
          value = entry,
          display = string.format('[%s] %s%s  %s:%d', entry.kind, container, entry.name, rel, entry.start_line),
          ordinal = entry.name .. ' ' .. (entry.container or '') .. ' ' .. rel,
          filename = entry.file,
          lnum = entry.start_line,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local rel = vim.fn.fnamemodify(entry.value.file, ':~:.')
        local text
        if entry.value.start_line == entry.value.end_line then
          text = string.format('@%s:%d (%s)', rel, entry.value.start_line, entry.value.name)
        else
          text = string.format('@%s:%d-%d (%s)', rel, entry.value.start_line, entry.value.end_line, entry.value.name)
        end

        vim.api.nvim_put({ text }, 'c', true, true)
      end)
      return true
    end,
  }):find()
end

return require('telescope').register_extension({
  exports = {
    symbols = symbols_picker,
  },
})
