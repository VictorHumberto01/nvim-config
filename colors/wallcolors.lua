-- Colorscheme file for wallpaper-generated colors (mini.base16)
local cache_file = vim.fn.stdpath("data") .. "/wallcolors.json"
local f = io.open(cache_file, "r")
if not f then
  vim.notify("No wallpaper colors found. Use <leader>W to select a wallpaper first.", vim.log.levels.WARN)
  vim.cmd("colorscheme tokyonight")
  return
end

local content = f:read("*a")
f:close()

local ok, parsed = pcall(vim.json.decode, content)
if not ok or not parsed or not parsed.background or not parsed.colors then
  vim.notify("Failed to parse wallpaper colors JSON.", vim.log.levels.ERROR)
  vim.cmd("colorscheme tokyonight")
  return
end

local palette = {
  base00 = parsed.background,
  base01 = parsed.colors.color0,
  base02 = parsed.colors.color8,
  base03 = parsed.colors.color8,
  base04 = parsed.colors.color7,
  base05 = parsed.foreground,
  base06 = parsed.colors.color15,
  base07 = parsed.colors.color15,
  base08 = parsed.colors.color1,
  base09 = parsed.colors.color3,
  base0A = parsed.colors.color11,
  base0B = parsed.colors.color2,
  base0C = parsed.colors.color6,
  base0D = parsed.colors.color4,
  base0E = parsed.colors.color5,
  base0F = parsed.colors.color9,
}

local function get_saturation()
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
  return 1.0 -- Padrão: 100% de saturação (sem redução)
end

local function hex_to_rgb(hex)
  hex = hex:gsub("#", "")
  if #hex == 3 then
    hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
  end
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  return r / 255, g / 255, b / 255
end

local function rgb_to_hex(r, g, b)
  local ir = math.floor(math.max(0, math.min(1, r)) * 255 + 0.5)
  local ig = math.floor(math.max(0, math.min(1, g)) * 255 + 0.5)
  local ib = math.floor(math.max(0, math.min(1, b)) * 255 + 0.5)
  return string.format("#%02x%02x%02x", ir, ig, ib)
end

local function rgb_to_hsl(r, g, b)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l
  l = (max + min) / 2

  if max == min then
    h = 0
    s = 0
  else
    local d = max - min
    s = l > 0.5 and (d / (2 - max - min)) or (d / (max + min))
    if max == r then
      h = ((g - b) / d) + (g < b and 6 or 0)
    elseif max == g then
      h = ((b - r) / d) + 2
    else
      h = ((r - g) / d) + 4
    end
    h = h / 6
  end

  return h, s, l
end

local function hue_to_rgb(p, q, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1 / 6 then return p + (q - p) * 6 * t end
  if t < 1 / 2 then return q end
  if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
  return p
end

local function hsl_to_rgb(h, s, l)
  if s == 0 then
    return l, l, l
  end
  local q = l < 0.5 and (l * (1 + s)) or (l + s - l * s)
  local p = 2 * l - q
  local r = hue_to_rgb(p, q, h + 1 / 3)
  local g = hue_to_rgb(p, q, h)
  local b = hue_to_rgb(p, q, h - 1 / 3)
  return r, g, b
end

local function adjust_saturation(hex, factor)
  if not hex or type(hex) ~= "string" or not hex:match("^#?[0-9a-fA-F]") then
    return hex
  end
  local r, g, b = hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(r, g, b)
  s = math.max(0, math.min(1, s * factor))
  local nr, ng, nb = hsl_to_rgb(h, s, l)
  return rgb_to_hex(nr, ng, nb)
end

local sat_factor = get_saturation()
if sat_factor ~= 1.0 then
  for k, v in pairs(palette) do
    palette[k] = adjust_saturation(v, sat_factor)
  end
end

-- Preserve the wallpaper hue, but keep foreground text readable.
local function ensure_lightness(hex, minimum)
  if not hex or type(hex) ~= "string" or not hex:match("^#?[0-9a-fA-F]") then
    return hex
  end
  local r, g, b = hex_to_rgb(hex)
  local h, s, l = rgb_to_hsl(r, g, b)
  if l < minimum then
    l = minimum
    local nr, ng, nb = hsl_to_rgb(h, s, l)
    return rgb_to_hex(nr, ng, nb)
  end
  return hex
end

palette.base04 = ensure_lightness(palette.base04, 0.65)
palette.base05 = ensure_lightness(palette.base05, 0.78)
palette.base06 = ensure_lightness(palette.base06, 0.84)
palette.base07 = ensure_lightness(palette.base07, 0.90)

local has_base16, base16 = pcall(require, "mini.base16")
if has_base16 then
  base16.setup({ palette = palette })
  vim.g.colors_name = "wallcolors"
else
  vim.notify("mini.base16 plugin is required for wallcolors.", vim.log.levels.ERROR)
end
