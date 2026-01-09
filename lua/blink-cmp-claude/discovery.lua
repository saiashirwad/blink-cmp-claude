local M = {}

local builtin = require('blink-cmp-claude.commands')

local function discover_custom_commands(config)
  if not config.discover.custom_commands then
    return {}
  end

  local commands = {}
  local dirs = {
    vim.fn.expand('~/.claude/commands'),
    vim.fn.getcwd() .. '/.claude/commands',
  }

  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local files = vim.fn.glob(dir .. '/**/*.md', false, true)
      for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ':t:r')
        local lines = vim.fn.readfile(file, '', 10)
        local desc = ''
        local in_frontmatter = false
        for _, line in ipairs(lines) do
          if line == '---' then
            in_frontmatter = not in_frontmatter
          elseif in_frontmatter then
            local d = line:match('^description:%s*(.+)$')
            if d then
              desc = d
              break
            end
          end
        end
        table.insert(commands, { name = name, desc = desc, custom = true })
      end
    end
  end

  return commands
end

local function discover_skills(config)
  if not config.discover.skills then
    return {}
  end

  local skills = {}
  local claude_md = vim.fn.expand('~/.claude/CLAUDE.md')
  if vim.fn.filereadable(claude_md) == 0 then
    return skills
  end

  local content = table.concat(vim.fn.readfile(claude_md), '\n')
  local seen = {}
  for skill in content:gmatch('`/([%w%-]+)`') do
    if not seen[skill] and not vim.tbl_contains({ 'commit', 'help', 'clear' }, skill) then
      seen[skill] = true
      table.insert(skills, { name = skill, desc = 'Custom skill', skill = true })
    end
  end

  return skills
end

local function discover_mcp_tools(config)
  if not config.discover.mcp then
    return {}
  end

  local tools = {}
  local mcp_dir = vim.fn.expand('~/.claude/plugins/marketplaces/claude-plugins-official/external_plugins')

  if vim.fn.isdirectory(mcp_dir) == 0 then
    return tools
  end

  local plugins = vim.fn.glob(mcp_dir .. '/*/.mcp.json', false, true)
  for _, plugin_file in ipairs(plugins) do
    local plugin_name = vim.fn.fnamemodify(vim.fn.fnamemodify(plugin_file, ':h'), ':t')
    table.insert(tools, {
      name = 'mcp__' .. plugin_name,
      desc = plugin_name .. ' MCP tools',
      mcp = true,
    })
  end

  return tools
end

function M.get_all_commands(config)
  local all = vim.deepcopy(builtin)
  vim.list_extend(all, discover_custom_commands(config))
  vim.list_extend(all, discover_skills(config))
  vim.list_extend(all, discover_mcp_tools(config))
  return all
end

return M
