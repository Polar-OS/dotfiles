return {
  'L3MON4D3/LuaSnip',
  version = 'v2.*',
  -- install jsregexp (optional!).
  build = 'make install_jsregexp',
  init = function()
    local ls = require 'luasnip'
    local fmt = require('luasnip.extras.fmt').fmt
    local snippets = {

      -- errors.Wrap
      ls.s(
        { trig = 'errw', dscr = 'errors.Wrap' },
        fmt([[errors.Wrap({}, "{}")]], {
          ls.i(1, 'err'),
          ls.i(2, 'failed to'),
        })
      ),

      -- errors.Wrapf
      ls.s(
        { trig = 'errwf', dscr = 'errors.Wrapf' },
        fmt([[errors.Wrapf({}, "{}", {})]], {
          ls.i(1, 'err'),
          ls.i(2, 'failed %v'),
          ls.i(3, 'args'),
        })
      ),
      -- for select
      ls.s(
        { trig = 'forsel', dscr = 'for select' },
        fmt(
          [[
for {{
	select {{
        case {} <- {}:
			      {}
        default:
            {}
	  }}
}}
]],
          {
            ls.c(1, { ls.i(1, 'ch'), ls.i(2, 'ch := ') }),
            ls.i(2, 'ch'),
            ls.i(3, 'break'),
            ls.i(0, ''),
          }
        )
      ),
      -- type switch
      ls.s(
        { trig = 'typesw', dscr = 'type switch' },
        fmt(
          [[
switch {} := {}.(type) {{
    case {}:
        {}
    default:
        {}
}}
]],
          {
            ls.i(1, 'v'),
            ls.i(2, 'i'),
            ls.i(3, 'int'),
            ls.i(4, 'fmt.Println("int")'),
            ls.i(0, ''),
          }
        )
      ),
      -- defer recover
      ls.s(
        { trig = 'dfr', dscr = 'defer recover' },
        fmt(
          [[
        defer func() {{
            if err := recover(); err != nil {{
       	        {}
            }}
        }}()]],
          {
            ls.i(1, ''),
          }
        )
      ),
    }

    ls.add_snippets('all', snippets)
  end,
  -- init = function()
  --   local ls = require 'luasnip'
  --   -- some shorthands...
  --   local s = ls.snippet
  --   local sn = ls.snippet_node
  --   local t = ls.text_node
  --   local i = ls.insert_node
  --   local f = ls.function_node
  --   local c = ls.choice_node
  --   local d = ls.dynamic_node
  --   local r = ls.restore_node
  --
  --   ls.add_snippets('all', {
  --     s('errw', {
  --       t 'return errors.Wrap(err, "',
  --       i(1),
  --       t '")',
  --     }),
  --   })
  -- end,
}
