local M = {}
_G.WallColors = M

function M.save_current_theme(theme_name)
  if not theme_name or theme_name == "" then
    return
  end
  local theme_file = vim.fn.stdpath("data") .. "/current_theme.txt"
  local f = io.open(theme_file, "w")
  if f then
    f:write(theme_name .. "\n")
    f:close()
  end
  if theme_name ~= "wallcolors" then
    local std_file = vim.fn.stdpath("data") .. "/last_standard_theme.txt"
    local sf = io.open(std_file, "w")
    if sf then
      sf:write(theme_name .. "\n")
      sf:close()
    end
  end
end

function M.get_last_standard_theme()
  local std_file = vim.fn.stdpath("data") .. "/last_standard_theme.txt"
  local sf = io.open(std_file, "r")
  if sf then
    local theme = vim.trim(sf:read("*a") or "")
    sf:close()
    if theme ~= "" and theme ~= "wallcolors" then
      return theme
    end
  end
  return "nord"
end

function M.apply_wallpaper_file(filepath)
  local img2iterm = vim.fn.expand("~/Programs/img2iterm/img2iterm")
  local cmd = string.format("%s -i %s -json", vim.fn.shellescape(img2iterm), vim.fn.shellescape(filepath))
  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Error generating colors: " .. output, vim.log.levels.ERROR)
    return
  end

  local ok, parsed = pcall(vim.json.decode, output)
  if not ok or not parsed or not parsed.background or not parsed.colors then
    vim.notify("Error parsing JSON: " .. output, vim.log.levels.ERROR)
    return
  end

  -- Save output to cache
  local cache_file = vim.fn.stdpath("data") .. "/wallcolors.json"
  local f = io.open(cache_file, "w")
  if f then
    f:write(output)
    f:close()
  end

  -- Apply wallcolors colorscheme
  local cs_ok, cs_err = pcall(vim.cmd.colorscheme, "wallcolors")
  if cs_ok then
    vim.notify("Wallpaper colors applied!", vim.log.levels.INFO)
  else
    vim.notify("Error applying wallcolors: " .. tostring(cs_err), vim.log.levels.ERROR)
  end
end

function M.pick_wallpaper()
  vim.ui.input({ prompt = "Wallpaper Directory: ", default = "~/Pictures", completion = "dir" }, function(input_path)
    if not input_path or input_path == "" then
      return
    end

    local expanded_path = vim.fn.expand(input_path)
    if vim.fn.isdirectory(expanded_path) == 0 then
      vim.notify("Directory not found: " .. input_path, vim.log.levels.ERROR)
      return
    end

    require("telescope.builtin").find_files({
      prompt_title = "Wallpapers (" .. input_path .. ")",
      cwd = expanded_path,
      attach_mappings = function(prompt_bufnr, map)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        local function on_select()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if not selection then
            return
          end

          local filepath = selection.path or selection.filename
          if not filepath:match("^/") then
            local cwd = expanded_path:match("/$") and expanded_path or (expanded_path .. "/")
            filepath = cwd .. filepath
          end
          filepath = vim.fn.expand(filepath)

          M.apply_wallpaper_file(filepath)
        end

        map({ "i", "n" }, "<CR>", on_select)
        return true
      end,
    })
  end)
end

function M.select_standard_theme()
  local has_snacks, snacks = pcall(require, "snacks")
  if has_snacks and snacks.picker and snacks.picker.colorschemes then
    snacks.picker.colorschemes()
  else
    local has_telescope, tb = pcall(require, "telescope.builtin")
    if has_telescope then
      tb.colorscheme({ enable_preview = true })
    else
      vim.ui.select(vim.fn.getcompletion("", "color"), {
        prompt = "Select Colorscheme: ",
      }, function(selected)
        if selected then
          vim.cmd.colorscheme(selected)
        end
      end)
    end
  end
end

function M.restore_wallpaper()
  local cache_file = vim.fn.stdpath("data") .. "/wallcolors.json"
  if not vim.uv.fs_stat(cache_file) then
    vim.notify("No wallpaper saved yet. Select a wallpaper first!", vim.log.levels.WARN)
    M.pick_wallpaper()
    return
  end
  local ok, err = pcall(vim.cmd.colorscheme, "wallcolors")
  if ok then
    vim.notify("Wallpaper colors reapplied!", vim.log.levels.INFO)
  else
    vim.notify("Error loading wallcolors: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.toggle_theme()
  local current = vim.g.colors_name or ""
  if current == "wallcolors" then
    local target = M.get_last_standard_theme()
    local ok, err = pcall(vim.cmd.colorscheme, target)
    if ok then
      vim.notify("Theme changed to: " .. target, vim.log.levels.INFO)
    else
      vim.notify("Error applying theme: " .. tostring(err), vim.log.levels.ERROR)
    end
  else
    M.restore_wallpaper()
  end
end

function M.get_saturation()
  if vim.g.wallcolors_saturation ~= nil then
    local s = tonumber(vim.g.wallcolors_saturation)
    if s then
      return s > 1 and (s / 100) or s
    end
  end
  local sat_file = vim.fn.stdpath("data") .. "/wallcolors_saturation.txt"
  local sf = io.open(sat_file, "r")
  if sf then
    local val = tonumber(vim.trim(sf:read("*a") or ""))
    sf:close()
    if val then
      return val > 1 and (val / 100) or val
    end
  end
  return 1.0 -- Default: 100% (no saturation reduction)
end

function M.set_saturation(val)
  local num = tonumber(val)
  if not num then
    vim.notify("Invalid saturation value: " .. tostring(val), vim.log.levels.ERROR)
    return
  end
  if num > 1.0 then
    num = num / 100.0
  end
  num = math.max(0.0, math.min(1.0, num))

  vim.g.wallcolors_saturation = num
  local sat_file = vim.fn.stdpath("data") .. "/wallcolors_saturation.txt"
  local sf = io.open(sat_file, "w")
  if sf then
    sf:write(tostring(num) .. "\n")
    sf:close()
  end

  local pct = math.floor(num * 100 + 0.5)
  vim.notify(string.format("Wallpaper saturation set to %d%%", pct), vim.log.levels.INFO)

  if vim.g.colors_name == "wallcolors" then
    pcall(vim.cmd.colorscheme, "wallcolors")
  end
end

function M.adjust_saturation_menu()
  local current_pct = math.floor(M.get_saturation() * 100 + 0.5)
  local presets = {
    { text = "100% (Recommended - Original saturation)", val = 1.0 },
    { text = "60%  (Softer - Pastel/Gruvbox style)", val = 0.60 },
    { text = "50%  (Medium - Neutral and comfortable tones)", val = 0.50 },
    { text = "80%  (Moderate - Slightly more vivid)", val = 0.80 },
    { text = "90%  (Vivid, but slightly balanced)", val = 0.90 },
    { text = "35%  (Low saturation - Almost monochromatic)", val = 0.35 },
    { text = "Custom (enter a percentage from 0 to 100)", val = "custom" },
  }

  vim.ui.select(presets, {
    prompt = string.format("Adjust Color Saturation (Current: %d%%):", current_pct),
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if not choice then
      return
    end
    if choice.val == "custom" then
      vim.ui.input({
        prompt = "Enter saturation percentage (0 to 100): ",
        default = tostring(current_pct),
      }, function(input)
        if input and vim.trim(input) ~= "" then
          local cleaned = vim.trim(input):gsub("%%", "")
          M.set_saturation(cleaned)
        end
      end)
    else
      M.set_saturation(choice.val)
    end
  end)
end

function M.theme_menu()
  local current_sat = math.floor(M.get_saturation() * 100 + 0.5)
  local options = {
    { text = "Select Wallpaper (choose an image)", action = M.pick_wallpaper },
    { text = string.format("Adjust Color Saturation (Current: %d%%)", current_sat), action = M.adjust_saturation_menu },
    { text = "Choose Default Colorscheme (Nord, Gruvbox, Everforest...)", action = M.select_standard_theme },
    { text = "Reapply Current Wallpaper Colors", action = M.restore_wallpaper },
    { text = "Toggle Wallpaper <-> Default Theme", action = M.toggle_theme },
  }

  vim.ui.select(options, {
    prompt = "Theme & Wallpaper Manager:",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if choice and choice.action then
      choice.action()
    end
  end)
end

-- Commands & autocmds setup
local function setup_commands_and_autocmds()
  vim.api.nvim_create_user_command("ThemeMenu", M.theme_menu, { desc = "Theme and Wallpaper Menu" })
  vim.api.nvim_create_user_command("ThemeSelect", M.select_standard_theme, { desc = "Select Default Colorscheme" })
  vim.api.nvim_create_user_command("WallpaperSelect", M.pick_wallpaper, { desc = "Select Wallpaper" })
  vim.api.nvim_create_user_command(
    "WallpaperColors",
    M.restore_wallpaper,
    { desc = "Reapply Wallpaper Colors" }
  )
  vim.api.nvim_create_user_command(
    "WallpaperSaturation",
    function(opts)
      if opts.args and vim.trim(opts.args) ~= "" then
        local cleaned = vim.trim(opts.args):gsub("%%", "")
        M.set_saturation(cleaned)
      else
        M.adjust_saturation_menu()
      end
    end,
    { nargs = "?", desc = "Adjust wallpaper color saturation (e.g. :WallpaperSaturation 70)" }
  )
  vim.api.nvim_create_user_command(
    "WallpaperToggle",
    M.toggle_theme,
    { desc = "Toggle between Wallpaper and Default Theme" }
  )

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("WallColorsPersistence", { clear = true }),
    callback = function(args)
      local name = args.match or vim.g.colors_name
      if name and name ~= "" and name ~= "minibase16" then
        M.save_current_theme(name)
      end
    end,
  })
end

return {
  {
    "nvim-mini/mini.base16",
    version = false,
  },
  {
    "nvim-telescope/telescope.nvim",
    init = function()
      setup_commands_and_autocmds()
    end,
    keys = {
      {
        "<leader>W",
        M.theme_menu,
        desc = "Theme / Wallpaper Menu",
      },
      {
        "<leader>ws",
        M.adjust_saturation_menu,
        desc = "Adjust Color Saturation",
      },
      {
        "<leader>wt",
        M.select_standard_theme,
        desc = "Select Default Colorscheme",
      },
      {
        "<leader>wp",
        M.pick_wallpaper,
        desc = "Select Wallpaper Image",
      },
      {
        "<leader>wc",
        M.restore_wallpaper,
        desc = "Reapply Wallpaper Colors",
      },
      {
        "<leader>wT",
        M.toggle_theme,
        desc = "Toggle Wallpaper / Default Theme",
      },
    },
  },
}
