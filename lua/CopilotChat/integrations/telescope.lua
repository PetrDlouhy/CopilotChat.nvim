local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local themes = require('telescope.themes')
local conf = require('telescope.config').values
local previewers = require('telescope.previewers')
local chat = require('CopilotChat')

local M = {}

--- Pick an action from a list of actions
---@param pick_actions CopilotChat.integrations.actions?: A table with the actions to pick from
---@param config CopilotChat.config?: The chat configuration
---@param opts table?: Telescope options
function M.pick(pick_actions, config, opts)
  if not pick_actions or not pick_actions.actions or vim.tbl_isempty(pick_actions.actions) then
    return
  end

  config = vim.tbl_extend('force', {
    selection = pick_actions.selection,
  }, config or {})

  opts = themes.get_dropdown(opts or {})
  pickers
    .new(opts, {
      prompt_title = pick_actions.prompt,
      finder = finders.new_table({
        results = vim.tbl_keys(pick_actions.actions),
      }),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry)
          vim.api.nvim_win_set_option(self.state.winid, 'wrap', true)
          vim.api.nvim_buf_set_lines(
            self.state.bufnr,
            0,
            -1,
            false,
            { pick_actions.actions[entry[1]] }
          )
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selected = action_state.get_selected_entry()
          if not selected or vim.tbl_isempty(selected) then
            return
          end
          chat.ask(pick_actions.actions[selected[1]], config)
        end)
        return true
      end,
    })
    :find()
end

return M
