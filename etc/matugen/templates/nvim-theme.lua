-- Matugen generated colorscheme
local M = {}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  vim.g.colors_name = "matugen"

  local h = vim.api.nvim_set_hl
  local c = {
    bg = "{{colors.surface.default.hex}}",
    fg = "{{colors.on_surface.default.hex}}",
    primary = "{{colors.primary.default.hex}}",
    on_primary = "{{colors.on_primary.default.hex}}",
    secondary = "{{colors.secondary.default.hex}}",
    on_secondary = "{{colors.on_secondary.default.hex}}",
    tertiary = "{{colors.tertiary.default.hex}}",
    on_tertiary = "{{colors.on_tertiary.default.hex}}",
    error = "{{colors.error.default.hex}}",
    surface_bright = "{{colors.surface_bright.default.hex}}",
    outline = "{{colors.outline.default.hex}}",
    outline_variant = "{{colors.outline_variant.default.hex}}",
  }

  -- Base
  h(0, "Normal", { fg = c.fg, bg = c.bg })
  h(0, "NormalFloat", { fg = c.fg, bg = c.surface_bright })
  h(0, "FloatBorder", { fg = c.outline, bg = c.surface_bright })
  h(0, "CursorLine", { bg = c.surface_bright })
  h(0, "LineNr", { fg = c.outline })
  h(0, "CursorLineNr", { fg = c.primary, bold = true })
  
  -- Syntax
  h(0, "Comment", { fg = c.outline_variant, italic = true })
  h(0, "Constant", { fg = c.tertiary })
  h(0, "String", { fg = c.secondary })
  h(0, "Character", { fg = c.secondary })
  h(0, "Number", { fg = c.tertiary })
  h(0, "Boolean", { fg = c.tertiary })
  h(0, "Array", { fg = c.tertiary })
  
  h(0, "Identifier", { fg = c.fg })
  h(0, "Function", { fg = c.primary, bold = true })
  
  h(0, "Statement", { fg = c.tertiary })
  h(0, "Operator", { fg = c.fg })
  h(0, "Keyword", { fg = c.tertiary, italic = true })
  h(0, "PreProc", { fg = c.secondary })
  h(0, "Type", { fg = c.primary })
  
  h(0, "Special", { fg = c.secondary })
  h(0, "Error", { fg = c.error })
  
  -- UI
  h(0, "Pmenu", { fg = c.fg, bg = c.surface_bright })
  h(0, "PmenuSel", { fg = c.on_primary, bg = c.primary })
  h(0, "Search", { fg = c.on_secondary, bg = c.secondary })
  h(0, "CurSearch", { fg = c.on_primary, bg = c.primary })
  
  -- Git
  h(0, "Added", { fg = c.secondary })
  h(0, "Changed", { fg = c.tertiary })
  h(0, "Removed", { fg = c.error })
  
  -- Diagnostics
  h(0, "DiagnosticError", { fg = c.error })
  h(0, "DiagnosticWarn", { fg = c.tertiary })
  h(0, "DiagnosticInfo", { fg = c.secondary })
  h(0, "DiagnosticHint", { fg = c.primary })
end

return M
