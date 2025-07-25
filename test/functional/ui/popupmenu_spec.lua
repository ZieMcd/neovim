local t = require('test.testutil')
local n = require('test.functional.testnvim')()
local Screen = require('test.functional.ui.screen')

local assert_alive = n.assert_alive
local clear, feed = n.clear, n.feed
local source = n.source
local insert = n.insert
local api = n.api
local async_meths = n.async_meths
local command = n.command
local fn = n.fn
local eq = t.eq
local pcall_err = t.pcall_err
local exec_lua = n.exec_lua
local exec = n.exec

describe('ui/ext_popupmenu', function()
  local screen
  before_each(function()
    clear()
    screen = Screen.new(60, 8, { rgb = true, ext_popupmenu = true })
    source([[
      function! TestComplete() abort
        call complete(1, [{'word':'foo', 'abbr':'fo', 'menu':'the foo', 'info':'foo-y', 'kind':'x'}, 'bar', 'spam'])
        return ''
      endfunction
    ]])
  end)

  local expected = {
    { 'fo', 'x', 'the foo', 'foo-y' },
    { 'bar', '', '', '' },
    { 'spam', '', '', '' },
  }

  it('works', function()
    feed('o<C-r>=TestComplete()<CR>')
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
    }

    feed('<c-p>')
    screen:expect {
      grid = [[
                                                                    |
        ^                                                            |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = -1, anchor = { 1, 1, 0 } },
    }

    -- down moves the selection in the menu, but does not insert anything
    feed('<down><down>')
    screen:expect {
      grid = [[
                                                                    |
        ^                                                            |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 1, anchor = { 1, 1, 0 } },
    }

    feed('<cr>')
    screen:expect([[
                                                                  |
      bar^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]])
  end)

  it('can be controlled by API', function()
    feed('o<C-r>=TestComplete()<CR>')
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(1, false, false, {})
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 1, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(2, true, false, {})
    screen:expect {
      grid = [[
                                                                  |
      spam^                                                        |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 2, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(0, true, true, {})
    screen:expect([[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]])

    feed('<c-w><C-r>=TestComplete()<CR>')
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(-1, false, false, {})
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = -1, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(1, true, false, {})
    screen:expect {
      grid = [[
                                                                  |
      bar^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 1, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(-1, true, false, {})
    screen:expect {
      grid = [[
                                                                  |
      ^                                                            |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = -1, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(0, true, false, {})
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
      popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
    }

    api.nvim_select_popupmenu_item(-1, true, true, {})
    screen:expect([[
                                                                  |
      ^                                                            |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]])

    command('set wildmenu')
    command('set wildoptions=pum')
    local expected_wildpum = {
      { 'define', '', '', '' },
      { 'jump', '', '', '' },
      { 'list', '', '', '' },
      { 'place', '', '', '' },
      { 'undefine', '', '', '' },
      { 'unplace', '', '', '' },
    }
    feed('<Esc>:sign <Tab>')
    screen:expect({
      grid = [[
                                                                  |*2
      {1:~                                                           }|*5
      :sign define^                                                |
    ]],
      popupmenu = { items = expected_wildpum, pos = 0, anchor = { 1, 7, 6 } },
    })

    api.nvim_select_popupmenu_item(-1, true, false, {})
    screen:expect({
      grid = [[
                                                                  |*2
      {1:~                                                           }|*5
      :sign ^                                                      |
    ]],
      popupmenu = { items = expected_wildpum, pos = -1, anchor = { 1, 7, 6 } },
    })

    api.nvim_select_popupmenu_item(5, true, false, {})
    screen:expect({
      grid = [[
                                                                  |*2
      {1:~                                                           }|*5
      :sign unplace^                                               |
    ]],
      popupmenu = { items = expected_wildpum, pos = 5, anchor = { 1, 7, 6 } },
    })

    api.nvim_select_popupmenu_item(-1, true, true, {})
    screen:expect({
      grid = [[
                                                                  |*2
      {1:~                                                           }|*5
      :sign ^                                                      |
    ]],
    })

    feed('<Tab>')
    screen:expect({
      grid = [[
                                                                  |*2
      {1:~                                                           }|*5
      :sign define^                                                |
    ]],
      popupmenu = { items = expected_wildpum, pos = 0, anchor = { 1, 7, 6 } },
    })

    api.nvim_select_popupmenu_item(5, true, true, {})
    screen:expect([[
                                                                  |*2
      {1:~                                                           }|*5
      :sign unplace^                                               |
    ]])

    local function test_pum_select_mappings()
      screen:set_option('ext_popupmenu', true)
      feed('<Esc>A<C-r>=TestComplete()<CR>')
      screen:expect {
        grid = [[
                                                                    |
        foo^                                                         |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]],
        popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
      }

      feed('<f1>')
      screen:expect {
        grid = [[
                                                                    |
        spam^                                                        |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]],
        popupmenu = { items = expected, pos = 2, anchor = { 1, 1, 0 } },
      }

      feed('<f2>')
      screen:expect {
        grid = [[
                                                                    |
        spam^                                                        |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]],
        popupmenu = { items = expected, pos = -1, anchor = { 1, 1, 0 } },
      }

      feed('<f3>')
      screen:expect([[
                                                                    |
        bar^                                                         |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]])

      feed('<Esc>:sign <Tab>')
      screen:expect({
        grid = [[
                                                                    |
        bar                                                         |
        {1:~                                                           }|*5
        :sign define^                                                |
      ]],
        popupmenu = { items = expected_wildpum, pos = 0, anchor = { 1, 7, 6 } },
      })

      feed('<f1>')
      screen:expect({
        grid = [[
                                                                    |
        bar                                                         |
        {1:~                                                           }|*5
        :sign list^                                                  |
      ]],
        popupmenu = { items = expected_wildpum, pos = 2, anchor = { 1, 7, 6 } },
      })

      feed('<f2>')
      screen:expect({
        grid = [[
                                                                    |
        bar                                                         |
        {1:~                                                           }|*5
        :sign ^                                                      |
      ]],
        popupmenu = { items = expected_wildpum, pos = -1, anchor = { 1, 7, 6 } },
      })

      feed('<f3>')
      screen:expect({
        grid = [[
                                                                    |
        bar                                                         |
        {1:~                                                           }|*5
        :sign jump^                                                  |
      ]],
      })

      -- also should work for builtin popupmenu
      screen:set_option('ext_popupmenu', false)
      feed('<Esc>A<C-r>=TestComplete()<CR>')
      screen:expect([[
                                                                    |
        foo^                                                         |
        {12:fo   x the foo }{1:                                             }|
        {4:bar            }{1:                                             }|
        {4:spam           }{1:                                             }|
        {1:~                                                           }|*2
        {5:-- INSERT --}                                                |
      ]])

      feed('<f1>')
      screen:expect([[
                                                                    |
        spam^                                                        |
        {4:fo   x the foo }{1:                                             }|
        {4:bar            }{1:                                             }|
        {12:spam           }{1:                                             }|
        {1:~                                                           }|*2
        {5:-- INSERT --}                                                |
      ]])

      feed('<f2>')
      screen:expect([[
                                                                    |
        spam^                                                        |
        {4:fo   x the foo }{1:                                             }|
        {4:bar            }{1:                                             }|
        {4:spam           }{1:                                             }|
        {1:~                                                           }|*2
        {5:-- INSERT --}                                                |
      ]])

      feed('<f3>')
      screen:expect([[
                                                                    |
        bar^                                                         |
        {1:~                                                           }|*5
        {5:-- INSERT --}                                                |
      ]])

      feed('<Esc>:sign <Tab>')
      screen:expect([[
                                                                    |
        bar  {12: define         }                                       |
        {1:~    }{4: jump           }{1:                                       }|
        {1:~    }{4: list           }{1:                                       }|
        {1:~    }{4: place          }{1:                                       }|
        {1:~    }{4: undefine       }{1:                                       }|
        {1:~    }{4: unplace        }{1:                                       }|
        :sign define^                                                |
      ]])

      feed('<f1>')
      screen:expect([[
                                                                    |
        bar  {4: define         }                                       |
        {1:~    }{4: jump           }{1:                                       }|
        {1:~    }{12: list           }{1:                                       }|
        {1:~    }{4: place          }{1:                                       }|
        {1:~    }{4: undefine       }{1:                                       }|
        {1:~    }{4: unplace        }{1:                                       }|
        :sign list^                                                  |
      ]])

      feed('<f2>')
      screen:expect([[
                                                                    |
        bar  {4: define         }                                       |
        {1:~    }{4: jump           }{1:                                       }|
        {1:~    }{4: list           }{1:                                       }|
        {1:~    }{4: place          }{1:                                       }|
        {1:~    }{4: undefine       }{1:                                       }|
        {1:~    }{4: unplace        }{1:                                       }|
        :sign ^                                                      |
      ]])

      feed('<f3>')
      screen:expect([[
                                                                    |
        bar                                                         |
        {1:~                                                           }|*5
        :sign jump^                                                  |
      ]])
    end

    command('map! <f1> <cmd>call nvim_select_popupmenu_item(2,v:true,v:false,{})<cr>')
    command('map! <f2> <cmd>call nvim_select_popupmenu_item(-1,v:false,v:false,{})<cr>')
    command('map! <f3> <cmd>call nvim_select_popupmenu_item(1,v:false,v:true,{})<cr>')
    test_pum_select_mappings()

    command('unmap! <f1>')
    command('unmap! <f2>')
    command('unmap! <f3>')
    exec_lua([[
      vim.keymap.set('!', '<f1>', function() vim.api.nvim_select_popupmenu_item(2, true, false, {}) end)
      vim.keymap.set('!', '<f2>', function() vim.api.nvim_select_popupmenu_item(-1, false, false, {}) end)
      vim.keymap.set('!', '<f3>', function() vim.api.nvim_select_popupmenu_item(1, false, true, {}) end)
    ]])
    test_pum_select_mappings()

    feed('<esc>ddiaa bb cc<cr>')
    feed('<c-x><c-n>')
    screen:expect([[
      aa bb cc                                                    |
      aa^                                                          |
      {12:aa             }{1:                                             }|
      {4:bb             }{1:                                             }|
      {4:cc             }{1:                                             }|
      {1:~                                                           }|*2
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 3}             |
    ]])

    feed('<f1>')
    screen:expect([[
      aa bb cc                                                    |
      cc^                                                          |
      {4:aa             }{1:                                             }|
      {4:bb             }{1:                                             }|
      {12:cc             }{1:                                             }|
      {1:~                                                           }|*2
      {5:-- Keyword Local completion (^N^P) }{6:match 3 of 3}             |
    ]])

    feed('<f2>')
    screen:expect([[
      aa bb cc                                                    |
      cc^                                                          |
      {4:aa             }{1:                                             }|
      {4:bb             }{1:                                             }|
      {4:cc             }{1:                                             }|
      {1:~                                                           }|*2
      {5:-- Keyword Local completion (^N^P) }{19:Back at original}         |
    ]])

    feed('<f3>')
    screen:expect([[
      aa bb cc                                                    |
      bb^                                                          |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]])
  end)

  local function source_complete_month()
    source([[
    function! TestCompleteMonth() abort
    call complete(1, ['January', 'February', 'March', 'April',
    \ 'May', 'June', 'July', 'August',
    \ 'September', 'October', 'November', 'December'])
    return ''
    endfunction
    ]])
  end

  describe('pum_set_height', function()
    it('can set pum height', function()
      source_complete_month()
      local month_expected = {
        { 'January', '', '', '' },
        { 'February', '', '', '' },
        { 'March', '', '', '' },
        { 'April', '', '', '' },
        { 'May', '', '', '' },
        { 'June', '', '', '' },
        { 'July', '', '', '' },
        { 'August', '', '', '' },
        { 'September', '', '', '' },
        { 'October', '', '', '' },
        { 'November', '', '', '' },
        { 'December', '', '', '' },
      }
      local pum_height = 6
      feed('o<C-r>=TestCompleteMonth()<CR>')
      api.nvim_ui_pum_set_height(pum_height)
      feed('<PageDown>')
      -- pos becomes pum_height-2 because it is subtracting 2 to keep some
      -- context in ins_compl_key2count()
      screen:expect {
        grid = [[
                                                                  |
      January^                                                     |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
        popupmenu = { items = month_expected, pos = pum_height - 2, anchor = { 1, 1, 0 } },
      }
    end)

    it('an error occurs if set 0 or less', function()
      api.nvim_ui_pum_set_height(1)
      eq('Expected pum height > 0', pcall_err(api.nvim_ui_pum_set_height, 0))
    end)

    it('an error occurs when ext_popupmenu is false', function()
      api.nvim_ui_pum_set_height(1)
      screen:set_option('ext_popupmenu', false)
      eq('It must support the ext_popupmenu option', pcall_err(api.nvim_ui_pum_set_height, 1))
    end)
  end)

  describe('pum_set_bounds', function()
    it('can set pum bounds', function()
      source_complete_month()
      local month_expected = {
        { 'January', '', '', '' },
        { 'February', '', '', '' },
        { 'March', '', '', '' },
        { 'April', '', '', '' },
        { 'May', '', '', '' },
        { 'June', '', '', '' },
        { 'July', '', '', '' },
        { 'August', '', '', '' },
        { 'September', '', '', '' },
        { 'October', '', '', '' },
        { 'November', '', '', '' },
        { 'December', '', '', '' },
      }
      local pum_height = 6
      feed('o<C-r>=TestCompleteMonth()<CR>')
      api.nvim_ui_pum_set_height(pum_height)
      -- set bounds w h r c
      api.nvim_ui_pum_set_bounds(10.5, 5.2, 6.3, 7.4)
      feed('<PageDown>')
      -- pos becomes pum_height-2 because it is subtracting 2 to keep some
      -- context in ins_compl_key2count()
      screen:expect {
        grid = [[
                                                                  |
      January^                                                     |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
      ]],
        popupmenu = { items = month_expected, pos = pum_height - 2, anchor = { 1, 1, 0 } },
      }
    end)

    it('no error occurs if row or col set less than 0', function()
      api.nvim_ui_pum_set_bounds(1.0, 1.0, 0.0, 1.5)
      api.nvim_ui_pum_set_bounds(1.0, 1.0, -1.0, 0.0)
      api.nvim_ui_pum_set_bounds(1.0, 1.0, 0.0, -1.0)
    end)

    it('an error occurs if width or height set 0 or less', function()
      api.nvim_ui_pum_set_bounds(1.0, 1.0, 0.0, 1.5)
      eq('Expected width > 0', pcall_err(api.nvim_ui_pum_set_bounds, 0.0, 1.0, 1.0, 0.0))
      eq('Expected height > 0', pcall_err(api.nvim_ui_pum_set_bounds, 1.0, -1.0, 1.0, 0.0))
    end)

    it('an error occurs when ext_popupmenu is false', function()
      api.nvim_ui_pum_set_bounds(1.0, 1.0, 0.0, 1.5)
      screen:set_option('ext_popupmenu', false)
      eq(
        'UI must support the ext_popupmenu option',
        pcall_err(api.nvim_ui_pum_set_bounds, 1.0, 1.0, 0.0, 1.5)
      )
    end)
  end)

  it('<PageUp>, <PageDown> works without ui_pum_set_height', function()
    source_complete_month()
    local month_expected = {
      { 'January', '', '', '' },
      { 'February', '', '', '' },
      { 'March', '', '', '' },
      { 'April', '', '', '' },
      { 'May', '', '', '' },
      { 'June', '', '', '' },
      { 'July', '', '', '' },
      { 'August', '', '', '' },
      { 'September', '', '', '' },
      { 'October', '', '', '' },
      { 'November', '', '', '' },
      { 'December', '', '', '' },
    }
    feed('o<C-r>=TestCompleteMonth()<CR>')
    feed('<PageDown>')
    screen:expect {
      grid = [[
                                                                |
    January^                                                     |
    {1:~                                                           }|*5
    {5:-- INSERT --}                                                |
    ]],
      popupmenu = { items = month_expected, pos = 3, anchor = { 1, 1, 0 } },
    }
    feed('<PageUp>')
    screen:expect {
      grid = [[
                                                                |
    January^                                                     |
    {1:~                                                           }|*5
    {5:-- INSERT --}                                                |
    ]],
      popupmenu = { items = month_expected, pos = 0, anchor = { 1, 1, 0 } },
    }
  end)

  it('works with wildoptions=pum', function()
    screen:try_resize(32, 10)
    command('set wildmenu')
    command('set wildoptions=pum')

    local wild_expected = {
      { 'define', '', '', '' },
      { 'jump', '', '', '' },
      { 'list', '', '', '' },
      { 'place', '', '', '' },
      { 'undefine', '', '', '' },
      { 'unplace', '', '', '' },
    }

    feed(':sign ')
    screen:expect([[
                                      |
      {1:~                               }|*8
      :sign ^                          |
    ]])
    eq(0, fn.wildmenumode())

    feed('<tab>')
    screen:expect {
      grid = [[
                                      |
      {1:~                               }|*8
      :sign define^                    |
    ]],
      popupmenu = { items = wild_expected, pos = 0, anchor = { 1, 9, 6 } },
    }
    eq(1, fn.wildmenumode())

    feed('<left>')
    screen:expect {
      grid = [[
                                      |
      {1:~                               }|*8
      :sign ^                          |
    ]],
      popupmenu = { items = wild_expected, pos = -1, anchor = { 1, 9, 6 } },
    }

    feed('<left>')
    screen:expect {
      grid = [[
                                      |
      {1:~                               }|*8
      :sign unplace^                   |
    ]],
      popupmenu = { items = wild_expected, pos = 5, anchor = { 1, 9, 6 } },
    }

    feed('x')
    screen:expect([[
                                      |
      {1:~                               }|*8
      :sign unplacex^                  |
    ]])
    feed('<esc>')

    -- #10042: make sure shift-tab also triggers the pum
    feed(':sign <S-tab>')
    screen:expect {
      grid = [[
                                      |
      {1:~                               }|*8
      :sign unplace^                   |
    ]],
      popupmenu = { items = wild_expected, pos = 5, anchor = { 1, 9, 6 } },
    }
    feed('<esc>')
    eq(0, fn.wildmenumode())

    -- check positioning with multibyte char in pattern
    command('e långfile1')
    command('sp långfile2')
    feed(':b lå<tab>')
    screen:expect {
      grid = [[
                                      |
      {1:~                               }|*3
      {3:långfile2                       }|
                                      |
      {1:~                               }|*2
      {2:långfile1                       }|
      :b långfile1^                    |
    ]],
      popupmenu = {
        anchor = { 1, 9, 3 },
        items = { { 'långfile1', '', '', '' }, { 'långfile2', '', '', '' } },
        pos = 0,
      },
    }
  end)

  it('does not interfere with mousemodel=popup', function()
    exec([[
      set mouse=a mousemodel=popup

      aunmenu PopUp
      " Delete the default MenuPopup event handler.
      autocmd! nvim.popupmenu
      menu PopUp.foo :let g:menustr = 'foo'<CR>
      menu PopUp.bar :let g:menustr = 'bar'<CR>
      menu PopUp.baz :let g:menustr = 'baz'<CR>
    ]])
    feed('o<C-r>=TestComplete()<CR>')
    screen:expect {
      grid = [[
                                                                  |
      foo^                                                         |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]],
      popupmenu = { items = expected, pos = 0, anchor = { 1, 1, 0 } },
    }

    feed('<c-p>')
    screen:expect {
      grid = [[
                                                                  |
      ^                                                            |
      {1:~                                                           }|*5
      {5:-- INSERT --}                                                |
    ]],
      popupmenu = { items = expected, pos = -1, anchor = { 1, 1, 0 } },
    }

    feed('<esc>')
    screen:expect([[
                                                                  |
      ^                                                            |
      {1:~                                                           }|*5
                                                                  |
    ]])
    feed('<RightMouse><0,0>')
    screen:expect([[
                                                                  |
      {4:^foo }                                                        |
      {4:bar }{1:                                                        }|
      {4:baz }{1:                                                        }|
      {1:~                                                           }|*3
                                                                  |
    ]])
    feed('<esc>')
    screen:expect([[
                                                                  |
      ^                                                            |
      {1:~                                                           }|*5
                                                                  |
    ]])
  end)
end)

describe("builtin popupmenu 'pumblend'", function()
  local screen
  before_each(function()
    clear()
    screen = Screen.new(60, 14)
    screen:add_extra_attr_ids({
      [100] = { background = Screen.colors.Gray55, foreground = Screen.colors.Grey45 },
      [101] = { background = Screen.colors.Gray55, foreground = Screen.colors.Grey0 },
      [102] = { background = tonumber('0x191919'), foreground = Screen.colors.Grey0 },
      [103] = { background = tonumber('0xffc1ff'), foreground = tonumber('0xe5a8e5') },
      [104] = { background = tonumber('0xffc1ff'), foreground = Screen.colors.Grey0 },
      [105] = { foreground = tonumber('0xffc1ff'), background = tonumber('0xe5a8e5'), bold = true },
      [106] = { foreground = Screen.colors.Grey55, background = Screen.colors.Gray45, bold = true },
      [107] = { background = tonumber('0xffc1e5'), foreground = Screen.colors.Grey0 },
      [108] = { background = tonumber('0xffc1e5'), foreground = tonumber('0xe5a8e5') },
      [109] = { background = tonumber('0xffc1ff'), foreground = tonumber('0x080202') },
      [110] = { background = tonumber('0xffc1ff'), bold = true, foreground = tonumber('0xf6ace9') },
      [111] = { background = tonumber('0xffc1ff'), foreground = tonumber('0xe5a8ff') },
      [112] = { background = tonumber('0xe5a8e5'), foreground = tonumber('0xffc1ff') },
      [113] = { background = Screen.colors.Gray45, foreground = Screen.colors.Grey55 },
      [114] = { background = Screen.colors.WebGray },
      [115] = { background = Screen.colors.Grey0 },
      [116] = { background = Screen.colors.Gray75, foreground = Screen.colors.Grey25 },
      [117] = { background = Screen.colors.Gray75, foreground = Screen.colors.Grey0 },
      [118] = { background = Screen.colors.Gray50, foreground = Screen.colors.Grey0 },
      [119] = { background = tonumber('0xffddff'), foreground = tonumber('0x7f5d7f') },
      [120] = { background = tonumber('0xffddff'), foreground = Screen.colors.Grey0 },
      [121] = { foreground = tonumber('0xffddff'), background = tonumber('0x7f5d7f'), bold = true },
      [123] = { foreground = tonumber('0xffddff'), background = Screen.colors.Grey0, bold = true },
      [124] = { foreground = Screen.colors.Gray75, background = Screen.colors.Grey25, bold = true },
      [125] = { background = tonumber('0xffdd7f'), foreground = Screen.colors.Grey0 },
      [126] = { background = tonumber('0xffdd7f'), foreground = tonumber('0x7f5d7f') },
      [127] = { background = tonumber('0xffddff'), bold = true, foreground = tonumber('0x290a0a') },
      [128] = { background = tonumber('0xffddff'), bold = true, foreground = tonumber('0xd27294') },
      [129] = { background = tonumber('0xffddff'), foreground = tonumber('0x7f5dff') },
      [130] = { background = tonumber('0x7f5d7f'), foreground = tonumber('0xffddff') },
      [131] = { background = Screen.colors.Grey0, foreground = tonumber('0xffddff') },
      [132] = { background = Screen.colors.Gray25, foreground = Screen.colors.Grey75 },
      [134] = { background = tonumber('0xffddff'), foreground = tonumber('0x00003f') },
      [135] = { foreground = tonumber('0x0c0c0c'), background = tonumber('0xe5a8e5') },
      [136] = { background = tonumber('0x7f5d7f'), bold = true, foreground = tonumber('0x3f3f3f') },
      [137] = { foreground = tonumber('0x3f3f3f'), background = tonumber('0x7f5d7f') },
      [138] = { background = Screen.colors.WebGray, blend = 0 },
      [139] = { background = 7, foreground = Screen.colors.Gray0 },
      [140] = { background = 7, foreground = 85 },
      [141] = { background = 225, foreground = Screen.colors.Gray0 },
      [142] = { background = 225, foreground = 209 },
      [143] = { foreground = 12 },
      [144] = { foreground = 2 },
    })
  end)

  it('RGB-color', function()
    command('syntax on')
    command('set mouse=a')
    command('set pumblend=10')
    insert([[
      Lorem ipsum dolor sit amet, consectetur
      adipisicing elit, sed do eiusmod tempor
      incididunt ut labore et dolore magna aliqua.
      Ut enim ad minim veniam, quis nostrud
      exercitation ullamco laboris nisi ut aliquip ex
      ea commodo consequat. Duis aute irure dolor in
      reprehenderit in voluptate velit esse cillum
      dolore eu fugiat nulla pariatur. Excepteur sint
      occaecat cupidatat non proident, sunt in culpa
      qui officia deserunt mollit anim id est
      laborum.]])
    command('match Statement /el/')
    command('2match Comment /ut/')
    command('1')
    command('split')
    command('/ol')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      ^incididunt ut labore et d{10:ol}ore magna aliqua.                |
      Ut enim ad minim veniam, quis nostrud                       |
      exercitation ullamco laboris nisi ut aliquip ex             |
      ea commodo consequat. Duis aute irure d{10:ol}or in              |
      {3:[No Name] [+]                                               }|
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing {15:el}it, sed do eiusmod tempor                     |
      incididunt {18:ut} labore et d{10:ol}ore magna aliqua.                |
      Ut enim ad minim veniam, quis nostrud                       |
      exercitation ullamco laboris nisi {18:ut} aliquip ex             |
      {2:[No Name] [+]                                               }|
                                                                  |
    ]])

    feed('Obla bla <c-x><c-n>')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla incididunt^                                          |
      incidid{100:u}{101:incididunt}{100:re et}{102: }d{10:ol}ore magna aliqua.                |
      Ut enim{103: }{104:ut}{103: minim veniam}{100:,} quis nostrud                       |
      exercit{103:a}{104:labore}{103:llamco la}{100:b}oris nisi ut aliquip ex             |
      {3:[No Nam}{105:e}{135:et}{105:[+]          }{106: }{3:                                    }|
      Lorem i{103:p}{104:dolor}{107:e}{108:l}{103:or sit a}{100:m}et, consectetur                     |
      adipisi{103:c}{104:magn}{109:a}{110:l}{103:it, sed d}{100:o} eiusmod tempor                     |
      bla bla{103: }{104:aliqua}{103:dunt     }{100: }                                    |
      incidid{103:u}{104:Ut}{103: }{111:ut}{103: labore et}{100: }d{10:ol}ore magna aliqua.                |
      Ut enim{103: }{104:enim}{103:inim veniam}{100:,} quis nostrud                       |
      {2:[No Nam}{112:e}{135:ad}{112:[+]          }{113: }{2:                                    }|
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
    ]])

    command('set pumblend=0')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla incididunt^                                          |
      incidid{114: incididunt     }{115: }d{10:ol}ore magna aliqua.                |
      Ut enim{4: ut             }{114: } quis nostrud                       |
      exercit{4: labore         }{114: }oris nisi ut aliquip ex             |
      {3:[No Nam}{4: et             }{114: }{3:                                    }|
      Lorem i{4: dolore         }{114: }et, consectetur                     |
      adipisi{4: magna          }{114: } eiusmod tempor                     |
      bla bla{4: aliqua         }{114: }                                    |
      incidid{4: Ut             }{114: }d{10:ol}ore magna aliqua.                |
      Ut enim{4: enim           }{114: } quis nostrud                       |
      {2:[No Nam}{4: ad             }{114: }{2:                                    }|
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
    ]])

    command('set pumblend=50')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla incididunt^                                          |
      incidid{116:u}{117:incididunt}{116:re et}{118: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:ut}{119: minim veniam}{116:,} quis nostrud                       |
      exercit{119:a}{120:labore}{119:llamco la}{116:b}oris nisi ut aliquip ex             |
      {3:[No Nam}{121:e}{136:et}{121:[+]          }{124: }{3:                                    }|
      Lorem i{119:p}{120:dolor}{125:e}{126:l}{119:or sit a}{116:m}et, consectetur                     |
      adipisi{119:c}{120:magn}{127:a}{128:l}{119:it, sed d}{116:o} eiusmod tempor                     |
      bla bla{119: }{120:aliqua}{119:dunt     }{116: }                                    |
      incidid{119:u}{120:Ut}{119: }{129:ut}{119: labore et}{116: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:enim}{119:inim veniam}{116:,} quis nostrud                       |
      {2:[No Nam}{130:e}{137:ad}{130:[+]          }{132: }{2:                                    }|
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
    ]])

    api.nvim_input_mouse('wheel', 'down', '', 0, 9, 40)
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla incididunt^                                          |
      incidid{116:u}{117:incididunt}{116:re et}{118: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:ut}{119: minim veniam}{116:,} quis nostrud                       |
      exercit{119:a}{120:labore}{119:llamco la}{116:b}oris nisi ut aliquip ex             |
      {3:[No Nam}{121:e}{136:et}{121:[+]          }{124: }{3:                                    }|
      incidid{119:u}{120:dol}{134:or}{120:e}{119:labore et}{116: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:magna}{119:nim veniam}{116:,} quis nostrud                       |
      exercit{119:a}{120:aliqua}{119:llamco la}{116:b}oris nisi {18:ut} aliquip ex             |
      ea comm{119:o}{120:Ut}{119: consequat. D}{116:u}is a{18:ut}e irure d{10:ol}or in              |
      reprehe{119:n}{120:enim}{119:t in v}{126:ol}{119:upt}{116:a}te v{15:el}it esse cillum                |
      {2:[No Nam}{130:e}{137:ad}{130:[+]          }{132: }{2:                                    }|
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
    ]])

    -- can disable blending for individual attribute. For instance current
    -- selected item. (also tests that `hi Pmenu*` take immediate effect)
    command('hi PMenuSel blend=0')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla incididunt^                                          |
      incidid{138: incididunt     }{118: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:ut}{119: minim veniam}{116:,} quis nostrud                       |
      exercit{119:a}{120:labore}{119:llamco la}{116:b}oris nisi ut aliquip ex             |
      {3:[No Nam}{121:e}{136:et}{121:[+]          }{124: }{3:                                    }|
      incidid{119:u}{120:dol}{134:or}{120:e}{119:labore et}{116: }d{10:ol}ore magna aliqua.                |
      Ut enim{119: }{120:magna}{119:nim veniam}{116:,} quis nostrud                       |
      exercit{119:a}{120:aliqua}{119:llamco la}{116:b}oris nisi {18:ut} aliquip ex             |
      ea comm{119:o}{120:Ut}{119: consequat. D}{116:u}is a{18:ut}e irure d{10:ol}or in              |
      reprehe{119:n}{120:enim}{119:t in v}{126:ol}{119:upt}{116:a}te v{15:el}it esse cillum                |
      {2:[No Nam}{130:e}{137:ad}{130:[+]          }{132: }{2:                                    }|
      {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
    ]])

    feed('<c-e>')
    screen:expect([[
      Lorem ipsum d{10:ol}or sit amet, consectetur                     |
      adipisicing elit, sed do eiusmod tempor                     |
      bla bla ^                                                    |
      incididunt ut labore et d{10:ol}ore magna aliqua.                |
      Ut enim ad minim veniam, quis nostrud                       |
      exercitation ullamco laboris nisi ut aliquip ex             |
      {3:[No Name] [+]                                               }|
      incididunt {18:ut} labore et d{10:ol}ore magna aliqua.                |
      Ut enim ad minim veniam, quis nostrud                       |
      exercitation ullamco laboris nisi {18:ut} aliquip ex             |
      ea commodo consequat. Duis a{18:ut}e irure d{10:ol}or in              |
      reprehenderit in v{10:ol}uptate v{15:el}it esse cillum                |
      {2:[No Name] [+]                                               }|
      {5:-- INSERT --}                                                |
    ]])
  end)

  it('256-color (non-RGB)', function()
    screen._options.rgb = false
    command('set pumblend=10')
    insert([[
      Lorem ipsum dolor sit amet, consectetur
      adipisicing elit, sed do eiusmod tempor
      incididunt ut labore et dolore magna aliqua.
      Ut enim ad minim veniam, quis nostrud
      laborum.]])

    feed('ggOdo<c-x><c-n>')
    screen:expect([[
      dolor^                                                       |
      {139:dolor}{140: ipsum dol}or sit amet, consectetur                     |
      {141:do}{142:ipisicing eli}t, sed do eiusmod tempor                     |
      {141:dolore}{142:dunt ut l}abore et dolore magna aliqua.                |
      Ut enim ad minim veniam, quis nostrud                       |
      laborum.                                                    |
      {143:~                                                           }|*7
      {5:-- Keyword Local completion (^N^P) }{144:match 1 of 3}             |
    ]])
  end)
end)

describe('builtin popupmenu', function()
  before_each(clear)

  local function with_ext_multigrid(multigrid)
    local screen
    before_each(function()
      screen = Screen.new(32, 20, { ext_multigrid = multigrid })
      screen:add_extra_attr_ids({
        [100] = { foreground = Screen.colors.Yellow, background = Screen.colors.Green },
        [101] = { foreground = Screen.colors.White, background = Screen.colors.Green },
        [102] = { foreground = Screen.colors.Brown, bold = true, background = Screen.colors.Plum1 },
        [103] = { foreground = Screen.colors.DarkCyan, background = Screen.colors.Plum1 },
        [104] = { foreground = Screen.colors.SlateBlue, background = Screen.colors.Plum1 },
        [105] = { foreground = Screen.colors.Magenta1, background = Screen.colors.Plum1 },
        [106] = {
          foreground = Screen.colors.Red,
          italic = true,
          background = Screen.colors.Gray,
          strikethrough = true,
          underline = true,
        },
        [107] = {
          background = Screen.colors.Grey100,
          foreground = Screen.colors.Black,
          italic = true,
          bold = true,
          underline = true,
          strikethrough = true,
        },
        [108] = {
          italic = true,
          background = Screen.colors.Gray,
          underline = true,
          foreground = Screen.colors.Grey100,
        },
        [109] = {
          foreground = Screen.colors.Yellow,
          italic = true,
          bold = true,
          underline = true,
          background = Screen.colors.Pink,
        },
        [110] = { background = Screen.colors.Grey, foreground = Screen.colors.DarkYellow },
        [111] = { background = Screen.colors.Plum1, foreground = Screen.colors.DarkBlue },
        [112] = { background = Screen.colors.Plum1, foreground = Screen.colors.DarkGreen },
        -- popup non-selected item
        n = { background = Screen.colors.Plum1 },
        -- popup scrollbar knob
        c = { background = Screen.colors.Black },
        ks = { foreground = Screen.colors.Red, background = Screen.colors.Grey },
        kn = { foreground = Screen.colors.Red, background = Screen.colors.Plum1 },
        xs = { foreground = Screen.colors.Black, background = Screen.colors.Grey },
        xn = { foreground = Screen.colors.White, background = Screen.colors.Plum1 },
        ms = { foreground = Screen.colors.Blue, background = Screen.colors.Grey },
        mn = { foreground = Screen.colors.Blue, background = Screen.colors.Plum1 },
        ds = { foreground = Screen.colors.DarkRed, background = Screen.colors.Grey },
        dn = { foreground = Screen.colors.DarkRed, background = Screen.colors.Plum1 },
        ums = {
          foreground = Screen.colors.Blue,
          background = Screen.colors.Grey,
          underline = true,
        },
        umn = {
          foreground = Screen.colors.Blue,
          background = Screen.colors.Plum1,
          underline = true,
        },
        uds = {
          foreground = Screen.colors.DarkRed,
          background = Screen.colors.Grey,
          underline = true,
        },
        udn = {
          foreground = Screen.colors.DarkRed,
          background = Screen.colors.Plum1,
          underline = true,
        },
      })
    end)

    it('with preview-window above', function()
      feed(':ped<CR><c-w>4+')
      feed('iaa bb cc dd ee ff gg hh ii jj<cr>')
      feed('<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:--------------------------------]|*8
          {2:[No Name] [Preview][+]          }|
          [2:--------------------------------]|*9
          {3:[No Name] [+]                   }|
          [3:--------------------------------]|
        ## grid 2
          aa bb cc dd ee ff gg hh ii jj   |
          aa^                              |
          {1:~                               }|*7
        ## grid 3
          {5:-- }{6:match 1 of 10}                |
        ## grid 4
          aa bb cc dd ee ff gg hh ii jj   |
          aa                              |
          {1:~                               }|*6
        ## grid 5
          {12:aa             }{c: }|
          {n:bb             }{c: }|
          {n:cc             }{c: }|
          {n:dd             }{c: }|
          {n:ee             }{c: }|
          {n:ff             }{c: }|
          {n:gg             }{12: }|
          {n:hh             }{12: }|
        ]],
          float_pos = { [5] = { -1, 'NW', 2, 2, 0, false, 100, 1, 11, 0 } },
        }
      else
        screen:expect([[
          aa bb cc dd ee ff gg hh ii jj   |
          aa                              |
          {1:~                               }|*6
          {2:[No Name] [Preview][+]          }|
          aa bb cc dd ee ff gg hh ii jj   |
          aa^                              |
          {12:aa             }{c: }{1:                }|
          {n:bb             }{c: }{1:                }|
          {n:cc             }{c: }{1:                }|
          {n:dd             }{c: }{1:                }|
          {n:ee             }{c: }{1:                }|
          {n:ff             }{c: }{1:                }|
          {n:gg             }{12: }{1:                }|
          {n:hh             }{12: }{3:                }|
          {5:-- }{6:match 1 of 10}                |
        ]])
      end
    end)

    it('with preview-window below', function()
      feed(':ped<CR><c-w>4+<c-w>r')
      feed('iaa bb cc dd ee ff gg hh ii jj<cr>')
      feed('<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*9
          {3:[No Name] [+]                   }|
          [4:--------------------------------]|*8
          {2:[No Name] [Preview][+]          }|
          [3:--------------------------------]|
        ## grid 2
          aa bb cc dd ee ff gg hh ii jj   |
          aa^                              |
          {1:~                               }|*7
        ## grid 3
          {5:-- }{6:match 1 of 10}                |
        ## grid 4
          aa bb cc dd ee ff gg hh ii jj   |
          aa                              |
          {1:~                               }|*6
        ## grid 5
          {12:aa             }{c: }|
          {n:bb             }{c: }|
          {n:cc             }{c: }|
          {n:dd             }{c: }|
          {n:ee             }{c: }|
          {n:ff             }{c: }|
          {n:gg             }{12: }|
          {n:hh             }{12: }|
        ]],
          float_pos = { [5] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        }
      else
        screen:expect([[
          aa bb cc dd ee ff gg hh ii jj   |
          aa^                              |
          {12:aa             }{c: }{1:                }|
          {n:bb             }{c: }{1:                }|
          {n:cc             }{c: }{1:                }|
          {n:dd             }{c: }{1:                }|
          {n:ee             }{c: }{1:                }|
          {n:ff             }{c: }{1:                }|
          {n:gg             }{12: }{1:                }|
          {n:hh             }{12: }{3:                }|
          aa bb cc dd ee ff gg hh ii jj   |
          aa                              |
          {1:~                               }|*6
          {2:[No Name] [Preview][+]          }|
          {5:-- }{6:match 1 of 10}                |
        ]])
      end
    end)

    it('with preview-window above, tall and inverted', function()
      feed(':ped<CR><c-w>8+')
      feed('iaa<cr>bb<cr>cc<cr>dd<cr>ee<cr>')
      feed('ff<cr>gg<cr>hh<cr>ii<cr>jj<cr>')
      feed('kk<cr>ll<cr>mm<cr>nn<cr>oo<cr>')
      feed('<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:--------------------------------]|*4
          {2:[No Name] [Preview][+]          }|
          [2:--------------------------------]|*13
          {3:[No Name] [+]                   }|
          [3:--------------------------------]|
        ## grid 2
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
          ii                              |
          jj                              |
          kk                              |
          ll                              |
          mm                              |
          nn                              |
          oo                              |
          aa^                              |
        ## grid 3
          {5:-- }{6:match 1 of 15}                |
        ## grid 4
          aa                              |
          bb                              |
          cc                              |
          dd                              |
        ## grid 5
          {12:aa             }{c: }|
          {n:bb             }{c: }|
          {n:cc             }{c: }|
          {n:dd             }{c: }|
          {n:ee             }{c: }|
          {n:ff             }{c: }|
          {n:gg             }{c: }|
          {n:hh             }{c: }|
          {n:ii             }{c: }|
          {n:jj             }{c: }|
          {n:kk             }{c: }|
          {n:ll             }{12: }|
          {n:mm             }{12: }|
        ]],
          float_pos = { [5] = { -1, 'SW', 2, 12, 0, false, 100, 1, 4, 0 } },
        }
      else
        screen:expect([[
          aa                              |
          bb                              |
          cc                              |
          dd                              |
          {12:aa             }{c: }{2:ew][+]          }|
          {n:bb             }{c: }                |
          {n:cc             }{c: }                |
          {n:dd             }{c: }                |
          {n:ee             }{c: }                |
          {n:ff             }{c: }                |
          {n:gg             }{c: }                |
          {n:hh             }{c: }                |
          {n:ii             }{c: }                |
          {n:jj             }{c: }                |
          {n:kk             }{c: }                |
          {n:ll             }{12: }                |
          {n:mm             }{12: }                |
          aa^                              |
          {3:[No Name] [+]                   }|
          {5:-- }{6:match 1 of 15}                |
        ]])
      end
    end)

    it('with preview-window above, short and inverted', function()
      feed(':ped<CR><c-w>4+')
      feed('iaa<cr>bb<cr>cc<cr>dd<cr>ee<cr>')
      feed('ff<cr>gg<cr>hh<cr>ii<cr>jj<cr>')
      feed('<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:--------------------------------]|*8
          {2:[No Name] [Preview][+]          }|
          [2:--------------------------------]|*9
          {3:[No Name] [+]                   }|
          [3:--------------------------------]|
        ## grid 2
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
          ii                              |
          jj                              |
          aa^                              |
        ## grid 3
          {5:-- }{6:match 1 of 10}                |
        ## grid 4
          aa                              |
          bb                              |
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
        ## grid 5
          {12:aa             }{c: }|
          {n:bb             }{c: }|
          {n:cc             }{c: }|
          {n:dd             }{c: }|
          {n:ee             }{c: }|
          {n:ff             }{c: }|
          {n:gg             }{c: }|
          {n:hh             }{c: }|
          {n:ii             }{12: }|
        ]],
          float_pos = { [5] = { -1, 'SW', 2, 8, 0, false, 100, 1, 8, 0 } },
        }
      else
        screen:expect([[
          aa                              |
          bb                              |
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
          {12:aa             }{c: }{2:ew][+]          }|
          {n:bb             }{c: }                |
          {n:cc             }{c: }                |
          {n:dd             }{c: }                |
          {n:ee             }{c: }                |
          {n:ff             }{c: }                |
          {n:gg             }{c: }                |
          {n:hh             }{c: }                |
          {n:ii             }{12: }                |
          aa^                              |
          {3:[No Name] [+]                   }|
          {5:-- }{6:match 1 of 10}                |
        ]])
      end
    end)

    it('with preview-window below, inverted', function()
      feed(':ped<CR><c-w>4+<c-w>r')
      feed('iaa<cr>bb<cr>cc<cr>dd<cr>ee<cr>')
      feed('ff<cr>gg<cr>hh<cr>ii<cr>jj<cr>')
      feed('<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*9
          {3:[No Name] [+]                   }|
          [4:--------------------------------]|*8
          {2:[No Name] [Preview][+]          }|
          [3:--------------------------------]|
        ## grid 2
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
          ii                              |
          jj                              |
          aa^                              |
        ## grid 3
          {5:-- }{6:match 1 of 10}                |
        ## grid 4
          aa                              |
          bb                              |
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
        ## grid 5
          {12:aa             }{c: }|
          {n:bb             }{c: }|
          {n:cc             }{c: }|
          {n:dd             }{c: }|
          {n:ee             }{c: }|
          {n:ff             }{c: }|
          {n:gg             }{12: }|
          {n:hh             }{12: }|
        ]],
          float_pos = { [5] = { -1, 'SW', 2, 8, 0, false, 100, 1, 0, 0 } },
        }
      else
        screen:expect([[
          {12:aa             }{c: }                |
          {n:bb             }{c: }                |
          {n:cc             }{c: }                |
          {n:dd             }{c: }                |
          {n:ee             }{c: }                |
          {n:ff             }{c: }                |
          {n:gg             }{12: }                |
          {n:hh             }{12: }                |
          aa^                              |
          {3:[No Name] [+]                   }|
          aa                              |
          bb                              |
          cc                              |
          dd                              |
          ee                              |
          ff                              |
          gg                              |
          hh                              |
          {2:[No Name] [Preview][+]          }|
          {5:-- }{6:match 1 of 10}                |
        ]])
      end
    end)

    describe('popup and preview window do not overlap', function()
      before_each(function()
        screen:try_resize(53, 20)
      end)

      -- oldtest: Test_popup_and_previewwindow_dump_pedit()
      it('with :pedit', function()
        exec([[
          set previewheight=9
          silent! pedit
          call setline(1, map(repeat(["ab"], 10), "v:val .. v:key"))
          exec "norm! G\<C-E>\<C-E>"
        ]])
        feed('o')
        n.poke_eventloop()
        feed('<C-X><C-N>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [4:-----------------------------------------------------]|*9
              {2:[No Name] [Preview][+]                               }|
              [2:-----------------------------------------------------]|*8
              {3:[No Name] [+]                                        }|
              [3:-----------------------------------------------------]|
            ## grid 2
              ab4                                                  |
              ab5                                                  |
              ab6                                                  |
              ab7                                                  |
              ab8                                                  |
              ab9                                                  |
              ab0^                                                  |
              {1:~                                                    }|
            ## grid 3
              {5:-- Keyword Local completion (^N^P) }{6:match 1 of 10}     |
            ## grid 4
              ab0                                                  |
              ab1                                                  |
              ab2                                                  |
              ab3                                                  |
              ab4                                                  |
              ab5                                                  |
              ab6                                                  |
              ab7                                                  |
              ab8                                                  |
            ## grid 5
              {12:ab0            }{c: }|
              {n:ab1            }{c: }|
              {n:ab2            }{c: }|
              {n:ab3            }{c: }|
              {n:ab4            }{12: }|
              {n:ab5            }{12: }|
              {n:ab6            }{12: }|
            ]],
            float_pos = { [5] = { -1, 'SW', 2, 6, 0, false, 100, 1, 9, 0 } },
          })
        else
          screen:expect([[
            ab0                                                  |
            ab1                                                  |
            ab2                                                  |
            ab3                                                  |
            ab4                                                  |
            ab5                                                  |
            ab6                                                  |
            ab7                                                  |
            ab8                                                  |
            {12:ab0            }{c: }{2:ew][+]                               }|
            {n:ab1            }{c: }                                     |
            {n:ab2            }{c: }                                     |
            {n:ab3            }{c: }                                     |
            {n:ab4            }{12: }                                     |
            {n:ab5            }{12: }                                     |
            {n:ab6            }{12: }                                     |
            ab0^                                                  |
            {1:~                                                    }|
            {3:[No Name] [+]                                        }|
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 10}     |
          ]])
        end
      end)

      -- oldtest: Test_popup_and_previewwindow_dump_pbuffer()
      it('with :pbuffer', function()
        exec([[
          set previewheight=9
          silent! pbuffer
          call setline(1, map(repeat(["ab"], 10), "v:val .. v:key"))
          exec "norm! G\<C-E>\<C-E>\<C-E>"
        ]])
        feed('o')
        n.poke_eventloop()
        feed('<C-X><C-N>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [4:-----------------------------------------------------]|*9
              {2:[No Name] [Preview][+]                               }|
              [2:-----------------------------------------------------]|*8
              {3:[No Name] [+]                                        }|
              [3:-----------------------------------------------------]|
            ## grid 2
              ab5                                                  |
              ab6                                                  |
              ab7                                                  |
              ab8                                                  |
              ab9                                                  |
              ab0^                                                  |
              {1:~                                                    }|*2
            ## grid 3
              {5:-- Keyword Local completion (^N^P) }{6:match 1 of 10}     |
            ## grid 4
              ab0                                                  |
              ab1                                                  |
              ab2                                                  |
              ab3                                                  |
              ab4                                                  |
              ab5                                                  |
              ab6                                                  |
              ab7                                                  |
              ab8                                                  |
            ## grid 5
              {12:ab0            }{c: }|
              {n:ab1            }{c: }|
              {n:ab2            }{c: }|
              {n:ab3            }{12: }|
              {n:ab4            }{12: }|
              {n:ab5            }{12: }|
            ]],
            float_pos = { [5] = { -1, 'SW', 2, 5, 0, false, 100, 1, 9, 0 } },
          })
        else
          screen:expect([[
            ab0                                                  |
            ab1                                                  |
            ab2                                                  |
            ab3                                                  |
            ab4                                                  |
            ab5                                                  |
            ab6                                                  |
            ab7                                                  |
            ab8                                                  |
            {12:ab0            }{c: }{2:ew][+]                               }|
            {n:ab1            }{c: }                                     |
            {n:ab2            }{c: }                                     |
            {n:ab3            }{12: }                                     |
            {n:ab4            }{12: }                                     |
            {n:ab5            }{12: }                                     |
            ab0^                                                  |
            {1:~                                                    }|*2
            {3:[No Name] [+]                                        }|
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 10}     |
          ]])
        end
      end)
    end)

    -- oldtest: Test_pum_with_preview_win()
    it('preview window opened during completion', function()
      exec([[
        funct Omni_test(findstart, base)
          if a:findstart
            return col(".") - 1
          endif
          return [#{word: "one", info: "1info"}, #{word: "two", info: "2info"}, #{word: "three", info: "3info"}]
        endfunc
        set omnifunc=Omni_test
        set completeopt-=popup completeopt+=longest,preview
      ]])
      feed('Gi<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
            ^                                |
            {1:~                               }|*18
          ## grid 3
            {5:-- }{19:Back at original}             |
          ## grid 4
            {n:one            }|
            {n:two            }|
            {n:three          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          ^                                |
          {n:one            }{1:                 }|
          {n:two            }{1:                 }|
          {n:three          }{1:                 }|
          {1:~                               }|*15
          {5:-- }{19:Back at original}             |
        ]])
      end
      feed('<C-N>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [5:--------------------------------]|*3
            {2:[Scratch] [Preview][-]          }|
            [2:--------------------------------]|*14
            {3:[No Name] [+]                   }|
            [3:--------------------------------]|
          ## grid 2
            one^                             |
            {1:~                               }|*13
          ## grid 3
            {5:-- }{6:match 1 of 3}                 |
          ## grid 4
            {12:one            }|
            {n:two            }|
            {n:three          }|
          ## grid 5
            1info                           |
            {1:~                               }|*2
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 5, 0 } },
        })
      else
        screen:expect([[
          1info                           |
          {1:~                               }|*2
          {2:[Scratch] [Preview][-]          }|
          one^                             |
          {12:one            }{1:                 }|
          {n:two            }{1:                 }|
          {n:three          }{1:                 }|
          {1:~                               }|*10
          {3:[No Name] [+]                   }|
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
    end)

    -- oldtest: Test_scrollbar_on_wide_char()
    it('scrollbar overwrites half of double-width char below properly', function()
      screen:try_resize(32, 10)
      exec([[
        call setline(1, ['a', '            啊啊啊',
                            \ '             哦哦哦',
                            \ '              呃呃呃'])
        call setline(5, range(10)->map({i, v -> 'aa' .. v .. 'bb'}))
      ]])
      feed('A<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*9
            [3:--------------------------------]|
          ## grid 2
            aa0bb^                           |
                        啊啊啊              |
                         哦哦哦             |
                          呃呃呃            |
            aa0bb                           |
            aa1bb                           |
            aa2bb                           |
            aa3bb                           |
            aa4bb                           |
          ## grid 3
            {5:-- }{6:match 1 of 10}                |
          ## grid 4
            {12:aa0bb          }{c: }|
            {n:aa1bb          }{c: }|
            {n:aa2bb          }{c: }|
            {n:aa3bb          }{c: }|
            {n:aa4bb          }{c: }|
            {n:aa5bb          }{c: }|
            {n:aa6bb          }{12: }|
            {n:aa7bb          }{12: }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          aa0bb^                           |
          {12:aa0bb          }{c: }啊              |
          {n:aa1bb          }{c: } 哦             |
          {n:aa2bb          }{c: }呃呃            |
          {n:aa3bb          }{c: }                |
          {n:aa4bb          }{c: }                |
          {n:aa5bb          }{c: }                |
          {n:aa6bb          }{12: }                |
          {n:aa7bb          }{12: }                |
          {5:-- }{6:match 1 of 10}                |
        ]])
      end
    end)

    describe('completeopt=popup shows preview in floatwin', function()
      before_each(function()
        --row must > 10
        screen:try_resize(40, 11)
        exec([[
          let g:list = [#{word: "one", info: "1info"}, #{word: "two", info: "2info"}, #{word: "looooooooooooooong"}]
          let g:bufnrs = []
          funct Omni_test(findstart, base)
            if a:findstart
              return col(".") - 1
            endif
            return g:list
          endfunc
          set omnifunc=Omni_test
          set completeopt=menu,popup
          funct Set_info()
            let comp_info = complete_info()
            if get(comp_info, 'preview_bufnr', 0) > 0
              call add(g:bufnrs, comp_info['preview_bufnr'])
            endif
            if comp_info['selected'] == 2
              call nvim__complete_set(comp_info['selected'], {"info": "3info"})
            endif
          endfunc
          funct TsHl()
            let comp_info = complete_info(['selected'])
            if get(comp_info, 'preview_bufnr', 0) > 0
              call v:lua.vim.treesitter.start(comp_info['preview_bufnr'], 'markdown')
            endif
            if comp_info['selected'] == 0
              call nvim__complete_set(comp_info['selected'], {"info": "```lua\nfunction test()\n  print('foo')\nend\n```"})
            endif
          endfunc
          augroup Group
            au!
            autocmd CompleteChanged * :call Set_info()
          augroup END
          funct TestTs()
            autocmd! Group
            autocmd CompleteChanged * call TsHl()
          endfunc
          funct Append_multipe()
            call extend(g:list, [#{word: "for .. ipairs", info: "```lua\nfor index, value in ipairs(t) do\n\t\nend\n```"}])
          endfunc
        ]])
      end)

      it('pum popup preview', function()
        feed('Gi<C-x><C-o>')
        --floating preview in right
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              one^                                     |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 1 of 3}                         |
            ## grid 4
              {n:1info}|
            ## grid 5
              {12:one                }|
              {n:two                }|
              {n:looooooooooooooong }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { -1, 'NW', 2, 1, 0, false, 100, 2, 1, 0 },
              [4] = { 1001, 'NW', 1, 1, 19, false, 50, 1, 1, 19 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 3,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 1,
                curline = 0,
                curcol = 0,
                linecount = 1,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            one^                                     |
            {12:one                }{n:1info}{1:                }|
            {n:two                }{1:                     }|
            {n:looooooooooooooong }{1:                     }|
            {1:~                                       }|*6
            {5:-- }{6:match 1 of 3}                         |
          ]])
        end

        -- delete one character make the pum width smaller than before
        -- info window position should be adjusted when popupmenu width changed
        feed('<BS>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              on^                                      |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 1 of 3}                         |
            ## grid 4
              {n:1info}|
            ## grid 5
              {12:one            }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { -1, 'NW', 2, 1, 0, false, 100, 2, 1, 0 },
              [4] = { 1001, 'NW', 1, 1, 15, false, 50, 1, 1, 15 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 2,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 1,
                curline = 0,
                curcol = 0,
                linecount = 1,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            on^                                      |
            {12:one            }{n:1info}{1:                    }|
            {1:~                                       }|*8
            {5:-- }{6:match 1 of 3}                         |
          ]])
        end

        -- when back to original the preview float should be closed.
        feed('<C-P>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              on^                                      |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{19:Back at original}                     |
            ## grid 4 (hidden)
              {n:1info}|
            ## grid 5
              {n:one            }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = { [5] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 2,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 1,
                curline = 0,
                curcol = 0,
                linecount = 1,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            on^                                      |
            {n:one            }{1:                         }|
            {1:~                                       }|*8
            {5:-- }{19:Back at original}                     |
          ]])
        end
        feed('<C-E><ESC>')
      end)

      it('nvim__set_complete', function()
        feed('S<C-X><C-O><C-N><C-N>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              looooooooooooooong^                      |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 3 of 3}                         |
            ## grid 4
              {n:3info}|
            ## grid 5
              {n:one                }|
              {n:two                }|
              {12:looooooooooooooong }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { -1, 'NW', 2, 1, 0, false, 100, 2, 1, 0 },
              [4] = { 1001, 'NW', 1, 1, 19, false, 50, 1, 1, 19 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 18,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 1,
                curline = 0,
                curcol = 0,
                linecount = 1,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            looooooooooooooong^                      |
            {n:one                3info}{1:                }|
            {n:two                }{1:                     }|
            {12:looooooooooooooong }{1:                     }|
            {1:~                                       }|*6
            {5:-- }{6:match 3 of 3}                         |
          ]])
        end
        feed('<C-E><ESC>')
      end)

      it('popup preview placed to left', function()
        insert(('test'):rep(5))
        feed('i<C-x><C-o>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              testtesttesttesttesone^t                 |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 1 of 3}                         |
            ## grid 4
              {n:1info}|
            ## grid 5
              {12: one                }|
              {n: two                }|
              {n: looooooooooooooong }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { -1, 'NW', 2, 1, 18, false, 100, 2, 1, 18 },
              [4] = { 1001, 'NW', 1, 1, 13, false, 50, 1, 1, 13 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 22,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 1,
                curline = 0,
                curcol = 0,
                linecount = 1,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            testtesttesttesttesone^t                 |
            {1:~            }{n:1info}{12: one                }{1:  }|
            {1:~                 }{n: two                }{1:  }|
            {1:~                 }{n: looooooooooooooong }{1:  }|
            {1:~                                       }|*6
            {5:-- }{6:match 1 of 3}                         |
          ]])
        end
        feed('<C-E><Esc>')
      end)

      it('works when scroll with treesitter highlight', function()
        command('call TestTs()')
        feed('S<C-x><C-o>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              one^                                     |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 1 of 3}                         |
            ## grid 4
              {mn:```}{102:lua}{n:         }|
              {102:function}{mn: }{103:test}{104:()}|
              {mn:  }{104:print(}{105:'foo'}{104:)}{n: }|
              {102:end}{n:            }|
              {mn:```}{n:            }|
            ## grid 5
              {12:one                }|
              {n:two                }|
              {n:looooooooooooooong }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { -1, 'NW', 2, 1, 0, false, 100, 2, 1, 0 },
              [4] = { 1001, 'NW', 1, 1, 19, false, 50, 1, 1, 19 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 3,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [4] = {
                win = 1001,
                topline = 0,
                botline = 5,
                curline = 0,
                curcol = 0,
                linecount = 5,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [4] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            one^                                     |
            {12:one                }{mn:```}{102:lua}{n:         }{1:      }|
            {n:two                }{102:function}{mn: }{103:test}{104:()}{1:      }|
            {n:looooooooooooooong }{mn:  }{104:print(}{105:'foo'}{104:)}{n: }{1:      }|
            {1:~                  }{102:end}{n:            }{1:      }|
            {1:~                  }{mn:```}{n:            }{1:      }|
            {1:~                                       }|*4
            {5:-- }{6:match 1 of 3}                         |
          ]])
        end
        feed('<C-E><ESC>')
      end)

      it('avoid modified original info text #test', function()
        command('call Append_multipe()')
        feed('S<C-x><C-o><C-P><C-P>')
        if multigrid then
          screen:expect({
            grid = [[
            ## grid 1
              [2:----------------------------------------]|*10
              [3:----------------------------------------]|
            ## grid 2
              for .. ipairs^                           |
              {1:~                                       }|*9
            ## grid 3
              {5:-- }{6:match 1 of 4}                         |
            ## grid 4
              {n:one                }|
              {n:two                }|
              {n:looooooooooooooong }|
              {12:for .. ipairs      }|
            ## grid 5
              {n:```lua              }|
              {n:for index, value in }|
              {n:ipairs(t) do        }|
              {n:                    }|
              {n:end                 }|
              {n:```                 }|
            ]],
            win_pos = { [2] = { height = 10, startcol = 0, startrow = 0, width = 40, win = 1000 } },
            float_pos = {
              [5] = { 1001, 'NW', 1, 1, 19, false, 50, 1, 1, 19 },
              [4] = { -1, 'NW', 2, 1, 0, false, 100, 2, 1, 0 },
            },
            win_viewport = {
              [2] = {
                win = 1000,
                topline = 0,
                botline = 2,
                curline = 0,
                curcol = 13,
                linecount = 1,
                sum_scroll_delta = 0,
              },
              [5] = {
                win = 1001,
                topline = 0,
                botline = 5,
                curline = 0,
                curcol = 0,
                linecount = 5,
                sum_scroll_delta = 0,
              },
            },
            win_viewport_margins = {
              [2] = { bottom = 0, left = 0, right = 0, top = 0, win = 1000 },
              [5] = { bottom = 0, left = 0, right = 0, top = 0, win = 1001 },
            },
          })
        else
          screen:expect([[
            for .. ipairs^                           |
            {n:one                ```lua              }{1: }|
            {n:two                for index, value in }{1: }|
            {n:looooooooooooooong ipairs(t) do        }{1: }|
            {12:for .. ipairs      }{n:                    }{1: }|
            {1:~                  }{n:end                 }{1: }|
            {1:~                  }{n:```                 }{1: }|
            {1:~                                       }|*3
            {5:-- }{6:match 1 of 4}                         |
          ]])
        end

        feed('<C-N><C-N><C-N><C-N><C-N>')
        if not multigrid then
          screen:expect_unchanged()
        end
        feed('<C-E><ESC>')
      end)

      it('popup info window reuses bufnr', function()
        feed('S<C-x><C-o><C-N>')
        eq(1, n.eval([[len(uniq(copy(g:bufnrs))) == 1]]))
      end)
    end)

    it('with vsplits', function()
      screen:try_resize(32, 8)
      insert('aaa aab aac\n')
      feed(':vsplit<cr>')
      if multigrid then
        screen:expect([[
        ## grid 1
          [4:--------------------]│[2:-----------]|*6
          {3:[No Name] [+]        }{2:<Name] [+] }|
          [3:--------------------------------]|
        ## grid 2
          aaa aab aac|
                     |
          {1:~          }|*4
        ## grid 3
          :vsplit                         |
        ## grid 4
          aaa aab aac         |
          ^                    |
          {1:~                   }|*4
        ]])
      else
        screen:expect([[
          aaa aab aac         │aaa aab aac|
          ^                    │           |
          {1:~                   }│{1:~          }|*4
          {3:[No Name] [+]        }{2:<Name] [+] }|
          :vsplit                         |
        ]])
      end

      feed('ibbb a<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:--------------------]│[2:-----------]|*6
          {3:[No Name] [+]        }{2:<Name] [+] }|
          [3:--------------------------------]|
        ## grid 2
          aaa aab aac|
          bbb aaa    |
          {1:~          }|*4
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          aaa aab aac         |
          bbb aaa^             |
          {1:~                   }|*4
        ## grid 5
          {12: aaa            }|
          {n: aab            }|
          {n: aac            }|
        ]],
          float_pos = { [5] = { -1, 'NW', 4, 2, 3, false, 100, 1, 2, 3 } },
        }
      else
        screen:expect([[
          aaa aab aac         │aaa aab aac|
          bbb aaa^             │bbb aaa    |
          {1:~  }{12: aaa            }{1: }│{1:~          }|
          {1:~  }{n: aab            }{1: }│{1:~          }|
          {1:~  }{n: aac            }{1: }│{1:~          }|
          {1:~                   }│{1:~          }|
          {3:[No Name] [+]        }{2:<Name] [+] }|
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end

      feed('<esc><c-w><c-w>oc a<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:-----------]│[2:--------------------]|*6
          {2:<Name] [+]  }{3:[No Name] [+]       }|
          [3:--------------------------------]|
        ## grid 2
          aaa aab aac         |
          bbb aaa             |
          c aaa^               |
          {1:~                   }|*3
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          aaa aab aac|
          bbb aaa    |
          c aaa      |
          {1:~          }|*3
        ## grid 5
          {12: aaa            }|
          {n: aab            }|
          {n: aac            }|
        ]],
          float_pos = { [5] = { -1, 'NW', 2, 3, 1, false, 100, 1, 3, 13 } },
        }
      else
        screen:expect([[
          aaa aab aac│aaa aab aac         |
          bbb aaa    │bbb aaa             |
          c aaa      │c aaa^               |
          {1:~          }│{1:~}{12: aaa            }{1:   }|
          {1:~          }│{1:~}{n: aab            }{1:   }|
          {1:~          }│{1:~}{n: aac            }{1:   }|
          {2:<Name] [+]  }{3:[No Name] [+]       }|
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end

      feed('bcdef ccc a<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:-----------]│[2:--------------------]|*6
          {2:<Name] [+]  }{3:[No Name] [+]       }|
          [3:--------------------------------]|
        ## grid 2
          aaa aab aac         |
          bbb aaa             |
          c aaabcdef ccc aaa^  |
          {1:~                   }|*3
        ## grid 3
          {5:-- }{6:match 1 of 4}                 |
        ## grid 4
          aaa aab aac|
          bbb aaa    |
          c aaabcdef |
          ccc aaa    |
          {1:~          }|*2
        ## grid 5
          {12: aaa     }|
          {n: aab     }|
          {n: aac     }|
          {n: aaabcdef}|
        ]],
          float_pos = { [5] = { -1, 'NW', 2, 3, 11, false, 100, 1, 3, 23 } },
        }
      else
        screen:expect([[
          aaa aab aac│aaa aab aac         |
          bbb aaa    │bbb aaa             |
          c aaabcdef │c aaabcdef ccc aaa^  |
          ccc aaa    │{1:~          }{12: aaa     }|
          {1:~          }│{1:~          }{n: aab     }|
          {1:~          }│{1:~          }{n: aac     }|
          {2:<Name] [+]  }{3:[No Name] [}{n: aaabcdef}|
          {5:-- }{6:match 1 of 4}                 |
        ]])
      end

      feed('\n<c-x><c-n>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [4:-----------]│[2:--------------------]|*6
          {2:<Name] [+]  }{3:[No Name] [+]       }|
          [3:--------------------------------]|
        ## grid 2
          aaa aab aac         |
          bbb aaa             |
          c aaabcdef ccc aaa  |
          aaa^                 |
          {1:~                   }|*2
        ## grid 3
          {5:-- }{6:match 1 of 6}                 |
        ## grid 4
          aaa aab aac|
          bbb aaa    |
          c aaabcdef |
          ccc aaa    |
          aaa        |
          {1:~          }|
        ## grid 5
          {12: aaa            }{c: }|
          {n: aab            }{12: }|
          {n: aac            }{12: }|
        ]],
          float_pos = { [5] = { -1, 'NW', 2, 4, -1, false, 100, 1, 4, 11 } },
        }
      else
        screen:expect([[
          aaa aab aac│aaa aab aac         |
          bbb aaa    │bbb aaa             |
          c aaabcdef │c aaabcdef ccc aaa  |
          ccc aaa    │aaa^                 |
          aaa        {12: aaa            }{c: }{1:    }|
          {1:~          }{n: aab            }{12: }{1:    }|
          {2:<Name] [+] }{n: aac            }{12: }{3:    }|
          {5:-- }{6:match 1 of 6}                 |
        ]])
      end
    end)

    it('with split and scroll', function()
      screen:try_resize(60, 14)
      command('split')
      command('set completeopt+=noinsert')
      command('set mouse=a')
      insert([[
          Lorem ipsum dolor sit amet, consectetur
          adipisicing elit, sed do eiusmod tempor
          incididunt ut labore et dolore magna aliqua.
          Ut enim ad minim veniam, quis nostrud
          exercitation ullamco laboris nisi ut aliquip ex
          ea commodo consequat. Duis aute irure dolor in
          reprehenderit in voluptate velit esse cillum
          dolore eu fugiat nulla pariatur. Excepteur sint
          occaecat cupidatat non proident, sunt in culpa
          qui officia deserunt mollit anim id est
          laborum.
        .
      ]])

      if multigrid then
        screen:expect([[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 3
                                                                        |
          ## grid 4
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
              laborum.                                                  |
            .                                                           |
            ^                                                            |
        ]])
      else
        screen:expect([[
            dolore eu fugiat nulla pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
            laborum.                                                  |
          .                                                           |
          ^                                                            |
          {3:[No Name] [+]                                               }|
            Lorem ipsum dolor sit amet, consectetur                   |
            adipisicing elit, sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
          {2:[No Name] [+]                                               }|
                                                                      |
        ]])
      end

      feed('ggOEst <c-x><c-p>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
            Est                                                         |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est ^                                                        |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: sunt           }{12: }|
            {n: in             }{12: }|
            {n: culpa          }{12: }|
            {n: qui            }{12: }|
            {n: officia        }{12: }|
            {n: deserunt       }{12: }|
            {n: mollit         }{12: }|
            {n: anim           }{12: }|
            {n: id             }{12: }|
            {n: est            }{12: }|
            {n: laborum        }{c: }|
            {12: Est            }{c: }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        screen:expect([[
          Est ^                                                        |
            L{n: sunt           }{12: }sit amet, consectetur                   |
            a{n: in             }{12: }sed do eiusmod tempor                   |
            i{n: culpa          }{12: }re et dolore magna aliqua.              |
            U{n: qui            }{12: }eniam, quis nostrud                     |
            e{n: officia        }{12: }co laboris nisi ut aliquip ex           |
          {3:[No}{n: deserunt       }{12: }{3:                                        }|
          Est{n: mollit         }{12: }                                        |
            L{n: anim           }{12: }sit amet, consectetur                   |
            a{n: id             }{12: }sed do eiusmod tempor                   |
            i{n: est            }{12: }re et dolore magna aliqua.              |
            U{n: laborum        }{c: }eniam, quis nostrud                     |
          {2:[No}{12: Est            }{c: }{2:                                        }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      if multigrid then
        api.nvim_input_mouse('wheel', 'down', '', 2, 9, 33)
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est ^                                                        |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: sunt           }{12: }|
            {n: in             }{12: }|
            {n: culpa          }{12: }|
            {n: qui            }{12: }|
            {n: officia        }{12: }|
            {n: deserunt       }{12: }|
            {n: mollit         }{12: }|
            {n: anim           }{12: }|
            {n: id             }{12: }|
            {n: est            }{12: }|
            {n: laborum        }{c: }|
            {12: Est            }{c: }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        api.nvim_input_mouse('wheel', 'down', '', 0, 9, 40)
        screen:expect([[
          Est ^                                                        |
            L{n: sunt           }{12: }sit amet, consectetur                   |
            a{n: in             }{12: }sed do eiusmod tempor                   |
            i{n: culpa          }{12: }re et dolore magna aliqua.              |
            U{n: qui            }{12: }eniam, quis nostrud                     |
            e{n: officia        }{12: }co laboris nisi ut aliquip ex           |
          {3:[No}{n: deserunt       }{12: }{3:                                        }|
            i{n: mollit         }{12: }re et dolore magna aliqua.              |
            U{n: anim           }{12: }eniam, quis nostrud                     |
            e{n: id             }{12: }co laboris nisi ut aliquip ex           |
            e{n: est            }{12: }at. Duis aute irure dolor in            |
            r{n: laborum        }{c: }oluptate velit esse cillum              |
          {2:[No}{12: Est            }{c: }{2:                                        }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      feed('e')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est e^                                                       |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: elit           }|
            {n: eiusmod        }|
            {n: et             }|
            {n: enim           }|
            {n: exercitation   }|
            {n: ex             }|
            {n: ea             }|
            {n: esse           }|
            {n: eu             }|
            {12: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        screen:expect([[
          Est e^                                                       |
            L{n: elit           } sit amet, consectetur                   |
            a{n: eiusmod        } sed do eiusmod tempor                   |
            i{n: et             }ore et dolore magna aliqua.              |
            U{n: enim           }veniam, quis nostrud                     |
            e{n: exercitation   }mco laboris nisi ut aliquip ex           |
          {3:[No}{n: ex             }{3:                                         }|
            i{n: ea             }ore et dolore magna aliqua.              |
            U{n: esse           }veniam, quis nostrud                     |
            e{n: eu             }mco laboris nisi ut aliquip ex           |
            e{12: est            }uat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      if multigrid then
        api.nvim_input_mouse('wheel', 'up', '', 2, 9, 33)
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
            Est e                                                       |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est e^                                                       |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: elit           }|
            {n: eiusmod        }|
            {n: et             }|
            {n: enim           }|
            {n: exercitation   }|
            {n: ex             }|
            {n: ea             }|
            {n: esse           }|
            {n: eu             }|
            {12: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        api.nvim_input_mouse('wheel', 'up', '', 0, 9, 40)
        screen:expect([[
          Est e^                                                       |
            L{n: elit           } sit amet, consectetur                   |
            a{n: eiusmod        } sed do eiusmod tempor                   |
            i{n: et             }ore et dolore magna aliqua.              |
            U{n: enim           }veniam, quis nostrud                     |
            e{n: exercitation   }mco laboris nisi ut aliquip ex           |
          {3:[No}{n: ex             }{3:                                         }|
          Est{n: ea             }                                         |
            L{n: esse           } sit amet, consectetur                   |
            a{n: eu             } sed do eiusmod tempor                   |
            i{12: est            }ore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      feed('s')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
            Est es                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est es^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: esse           }|
            {12: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        screen:expect([[
          Est es^                                                      |
            L{n: esse           } sit amet, consectetur                   |
            a{12: est            } sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
          {3:[No Name] [+]                                               }|
          Est es                                                      |
            Lorem ipsum dolor sit amet, consectetur                   |
            adipisicing elit, sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      if multigrid then
        api.nvim_input_mouse('wheel', 'down', '', 2, 9, 33)
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est es^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: esse           }|
            {12: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        api.nvim_input_mouse('wheel', 'down', '', 0, 9, 40)
        screen:expect([[
          Est es^                                                      |
            L{n: esse           } sit amet, consectetur                   |
            a{12: est            } sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
          {3:[No Name] [+]                                               }|
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
            ea commodo consequat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      feed('<bs>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
          ## grid 4
            Est e^                                                       |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: elit           }|
            {n: eiusmod        }|
            {n: et             }|
            {n: enim           }|
            {n: exercitation   }|
            {n: ex             }|
            {n: ea             }|
            {n: esse           }|
            {n: eu             }|
            {12: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        screen:expect([[
          Est e^                                                       |
            L{n: elit           } sit amet, consectetur                   |
            a{n: eiusmod        } sed do eiusmod tempor                   |
            i{n: et             }ore et dolore magna aliqua.              |
            U{n: enim           }veniam, quis nostrud                     |
            e{n: exercitation   }mco laboris nisi ut aliquip ex           |
          {3:[No}{n: ex             }{3:                                         }|
            i{n: ea             }ore et dolore magna aliqua.              |
            U{n: esse           }veniam, quis nostrud                     |
            e{n: eu             }mco laboris nisi ut aliquip ex           |
            e{12: est            }uat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 65}            |
        ]])
      end

      feed('<c-p>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 22 of 65}           |
          ## grid 4
            Est eu^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: elit           }|
            {n: eiusmod        }|
            {n: et             }|
            {n: enim           }|
            {n: exercitation   }|
            {n: ex             }|
            {n: ea             }|
            {n: esse           }|
            {12: eu             }|
            {n: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        screen:expect([[
          Est eu^                                                      |
            L{n: elit           } sit amet, consectetur                   |
            a{n: eiusmod        } sed do eiusmod tempor                   |
            i{n: et             }ore et dolore magna aliqua.              |
            U{n: enim           }veniam, quis nostrud                     |
            e{n: exercitation   }mco laboris nisi ut aliquip ex           |
          {3:[No}{n: ex             }{3:                                         }|
            i{n: ea             }ore et dolore magna aliqua.              |
            U{n: esse           }veniam, quis nostrud                     |
            e{12: eu             }mco laboris nisi ut aliquip ex           |
            e{n: est            }uat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 22 of 65}           |
        ]])
      end

      if multigrid then
        api.nvim_input_mouse('wheel', 'down', '', 2, 9, 33)
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 22 of 65}           |
          ## grid 4
            Est eu^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: elit           }|
            {n: eiusmod        }|
            {n: et             }|
            {n: enim           }|
            {n: exercitation   }|
            {n: ex             }|
            {n: ea             }|
            {n: esse           }|
            {12: eu             }|
            {n: est            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 3, false, 100, 1, 1, 3 } },
        })
      else
        api.nvim_input_mouse('wheel', 'down', '', 0, 9, 40)
        screen:expect([[
          Est eu^                                                      |
            L{n: elit           } sit amet, consectetur                   |
            a{n: eiusmod        } sed do eiusmod tempor                   |
            i{n: et             }ore et dolore magna aliqua.              |
            U{n: enim           }veniam, quis nostrud                     |
            e{n: exercitation   }mco laboris nisi ut aliquip ex           |
          {3:[No}{n: ex             }{3:                                         }|
            e{n: ea             }uat. Duis aute irure dolor in            |
            r{n: esse           }voluptate velit esse cillum              |
            d{12: eu             }nulla pariatur. Excepteur sint           |
            o{n: est            }t non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 22 of 65}           |
        ]])
      end

      fn.complete(4, { 'ea', 'eeeeeeeeeeeeeeeeee', 'ei', 'eo', 'eu', 'ey', 'eå', 'eä', 'eö' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- Keyword Local completion (^N^P) }{6:match 1 of 9}             |
          ## grid 4
            Est eu^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {12: ea                 }|
            {n: eeeeeeeeeeeeeeeeee }|
            {n: ei                 }|
            {n: eo                 }|
            {n: eu                 }|
            {n: ey                 }|
            {n: eå                 }|
            {n: eä                 }|
            {n: eö                 }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 2, false, 100, 1, 1, 2 } },
        })
      else
        screen:expect([[
          Est eu^                                                      |
            {12: ea                 }t amet, consectetur                   |
            {n: eeeeeeeeeeeeeeeeee }d do eiusmod tempor                   |
            {n: ei                 } et dolore magna aliqua.              |
            {n: eo                 }iam, quis nostrud                     |
            {n: eu                 } laboris nisi ut aliquip ex           |
          {3:[N}{n: ey                 }{3:                                      }|
            {n: eå                 }. Duis aute irure dolor in            |
            {n: eä                 }uptate velit esse cillum              |
            {n: eö                 }la pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 9}             |
        ]])
      end

      fn.complete(4, { 'ea', 'eee', 'ei', 'eo', 'eu', 'ey', 'eå', 'eä', 'eö' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- INSERT --}                                                |
          ## grid 4
            Est eu^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {12: ea             }|
            {n: eee            }|
            {n: ei             }|
            {n: eo             }|
            {n: eu             }|
            {n: ey             }|
            {n: eå             }|
            {n: eä             }|
            {n: eö             }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 2, false, 100, 1, 1, 2 } },
        })
      else
        screen:expect([[
          Est eu^                                                      |
            {12: ea             }r sit amet, consectetur                   |
            {n: eee            }, sed do eiusmod tempor                   |
            {n: ei             }bore et dolore magna aliqua.              |
            {n: eo             } veniam, quis nostrud                     |
            {n: eu             }amco laboris nisi ut aliquip ex           |
          {3:[N}{n: ey             }{3:                                          }|
            {n: eå             }quat. Duis aute irure dolor in            |
            {n: eä             } voluptate velit esse cillum              |
            {n: eö             } nulla pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- INSERT --}                                                |
        ]])
      end

      feed('<c-n>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- INSERT --}                                                |
          ## grid 4
            Esteee^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {n: ea             }|
            {12: eee            }|
            {n: ei             }|
            {n: eo             }|
            {n: eu             }|
            {n: ey             }|
            {n: eå             }|
            {n: eä             }|
            {n: eö             }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 2, false, 100, 1, 1, 2 } },
        })
      else
        screen:expect([[
          Esteee^                                                      |
            {n: ea             }r sit amet, consectetur                   |
            {12: eee            }, sed do eiusmod tempor                   |
            {n: ei             }bore et dolore magna aliqua.              |
            {n: eo             } veniam, quis nostrud                     |
            {n: eu             }amco laboris nisi ut aliquip ex           |
          {3:[N}{n: ey             }{3:                                          }|
            {n: eå             }quat. Duis aute irure dolor in            |
            {n: eä             } voluptate velit esse cillum              |
            {n: eö             } nulla pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- INSERT --}                                                |
        ]])
      end

      fn.complete(6, { 'foo', 'bar' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- INSERT --}                                                |
          ## grid 4
            Esteee^                                                      |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ## grid 5
            {12: foo            }|
            {n: bar            }|
          ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, 4, false, 100, 1, 1, 4 } },
        })
      else
        screen:expect([[
          Esteee^                                                      |
            Lo{12: foo            }sit amet, consectetur                   |
            ad{n: bar            }sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
          {3:[No Name] [+]                                               }|
            ea commodo consequat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
            dolore eu fugiat nulla pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- INSERT --}                                                |
        ]])
      end

      feed('<c-y>')
      if multigrid then
        screen:expect([[
          ## grid 1
            [4:------------------------------------------------------------]|*6
            {3:[No Name] [+]                                               }|
            [2:------------------------------------------------------------]|*5
            {2:[No Name] [+]                                               }|
            [3:------------------------------------------------------------]|
          ## grid 2
              ea commodo consequat. Duis aute irure dolor in            |
              reprehenderit in voluptate velit esse cillum              |
              dolore eu fugiat nulla pariatur. Excepteur sint           |
              occaecat cupidatat non proident, sunt in culpa            |
              qui officia deserunt mollit anim id est                   |
          ## grid 3
            {5:-- INSERT --}                                                |
          ## grid 4
            Esteefoo^                                                    |
              Lorem ipsum dolor sit amet, consectetur                   |
              adipisicing elit, sed do eiusmod tempor                   |
              incididunt ut labore et dolore magna aliqua.              |
              Ut enim ad minim veniam, quis nostrud                     |
              exercitation ullamco laboris nisi ut aliquip ex           |
          ]])
      else
        screen:expect([[
          Esteefoo^                                                    |
            Lorem ipsum dolor sit amet, consectetur                   |
            adipisicing elit, sed do eiusmod tempor                   |
            incididunt ut labore et dolore magna aliqua.              |
            Ut enim ad minim veniam, quis nostrud                     |
            exercitation ullamco laboris nisi ut aliquip ex           |
          {3:[No Name] [+]                                               }|
            ea commodo consequat. Duis aute irure dolor in            |
            reprehenderit in voluptate velit esse cillum              |
            dolore eu fugiat nulla pariatur. Excepteur sint           |
            occaecat cupidatat non proident, sunt in culpa            |
            qui officia deserunt mollit anim id est                   |
          {2:[No Name] [+]                                               }|
          {5:-- INSERT --}                                                |
        ]])
      end
    end)

    it('can be moved due to wrap or resize', function()
      feed('isome long prefix before the ')
      command('set completeopt+=noinsert,noselect')
      command('set linebreak')
      fn.complete(29, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
            some long prefix before the ^    |
            {1:~                               }|*18
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {n: word  }|
            {n: choice}|
            {n: text  }|
            {n: thing }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 25, false, 100, 1, 1, 25 } },
        })
      else
        screen:expect([[
          some long prefix before the ^    |
          {1:~                        }{n: word  }|
          {1:~                        }{n: choice}|
          {1:~                        }{n: text  }|
          {1:~                        }{n: thing }|
          {1:~                               }|*14
          {5:-- INSERT --}                    |
        ]])
      end

      feed('<c-p>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
            some long prefix before the     |
            thing^                           |
            {1:~                               }|*17
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {n:word           }|
            {n:choice         }|
            {n:text           }|
            {12:thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          some long prefix before the     |
          thing^                           |
          {n:word           }{1:                 }|
          {n:choice         }{1:                 }|
          {n:text           }{1:                 }|
          {12:thing          }{1:                 }|
          {1:~                               }|*13
          {5:-- INSERT --}                    |
        ]])
      end

      feed('<c-p>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
            some long prefix before the text|
            {1:^~                               }|
            {1:~                               }|*17
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {n: word  }|
            {n: choice}|
            {12: text  }|
            {n: thing }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 25, false, 100, 1, 1, 25 } },
        })
      else
        screen:expect([[
          some long prefix before the text|
          {1:^~                        }{n: word  }|
          {1:~                        }{n: choice}|
          {1:~                        }{12: text  }|
          {1:~                        }{n: thing }|
          {1:~                               }|*14
          {5:-- INSERT --}                    |
        ]])
      end

      screen:try_resize(30, 8)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:------------------------------]|*7
            [3:------------------------------]|
          ## grid 2
            some long prefix before the   |
            text^                          |
            {1:~                             }|*5
          ## grid 3
            {5:-- INSERT --}                  |
          ## grid 4
            {n:word           }|
            {n:choice         }|
            {12:text           }|
            {n:thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          some long prefix before the   |
          text^                          |
          {n:word           }{1:               }|
          {n:choice         }{1:               }|
          {12:text           }{1:               }|
          {n:thing          }{1:               }|
          {1:~                             }|
          {5:-- INSERT --}                  |
        ]])
      end

      screen:try_resize(50, 8)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------------------------]|*7
            [3:--------------------------------------------------]|
          ## grid 2
            some long prefix before the text^                  |
            {1:~                                                 }|*6
          ## grid 3
            {5:-- INSERT --}                                      |
          ## grid 4
            {n: word           }|
            {n: choice         }|
            {12: text           }|
            {n: thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 27, false, 100, 1, 1, 27 } },
        })
      else
        screen:expect([[
          some long prefix before the text^                  |
          {1:~                          }{n: word           }{1:       }|
          {1:~                          }{n: choice         }{1:       }|
          {1:~                          }{12: text           }{1:       }|
          {1:~                          }{n: thing          }{1:       }|
          {1:~                                                 }|*2
          {5:-- INSERT --}                                      |
        ]])
      end

      screen:try_resize(25, 10)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:-------------------------]|*9
            [3:-------------------------]|
          ## grid 2
            some long prefix before  |
            the text^                 |
            {1:~                        }|*7
          ## grid 3
            {5:-- INSERT --}             |
          ## grid 4
            {n: word           }|
            {n: choice         }|
            {12: text           }|
            {n: thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 3, false, 100, 1, 2, 3 } },
        })
      else
        screen:expect([[
          some long prefix before  |
          the text^                 |
          {1:~  }{n: word           }{1:      }|
          {1:~  }{n: choice         }{1:      }|
          {1:~  }{12: text           }{1:      }|
          {1:~  }{n: thing          }{1:      }|
          {1:~                        }|*3
          {5:-- INSERT --}             |
        ]])
      end

      screen:try_resize(12, 5)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:------------]|*4
            [3:------------]|
          ## grid 2
            some long   |
            prefix      |
            before the  |
            text^        |
          ## grid 3
            {5:-- INSERT --}|
          ## grid 4
            {n: word           }|
            {n: choice         }|
            {12: text           }|
            {n: thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 3, false, 100, 1, 2, 3 } },
        })
      else
        screen:expect([[
          some long   |
          prefix      |
          bef{n: word  }  |
          tex{n: }^        |
          {5:-- INSERT --}|
        ]])
      end

      -- can't draw the pum, but check we don't crash
      screen:try_resize(12, 2)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:------------]|
            [3:------------]|
          ## grid 2
            {1:<<<}t^        |
          ## grid 3
            {5:-- INSERT --}|
          ## grid 4
            {n: word           }|
            {n: choice         }|
            {12: text           }|
            {n: thing          }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 3, false, 100, 1, 2, 3 } },
        })
      else
        screen:expect([[
          {1:<<<}t^        |
          {5:-- INSERT --}|
        ]])
      end

      -- but state is preserved, pum reappears
      screen:try_resize(20, 8)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------]|*7
            [3:--------------------]|
          ## grid 2
            some long prefix    |
            before the text^     |
            {1:~                   }|*5
          ## grid 3
            {5:-- INSERT --}        |
          ## grid 4
            {n: word    }|
            {n: choice  }|
            {12: text    }|
            {n: thing   }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 10, false, 100, 1, 2, 10 } },
        })
      else
        screen:expect([[
          some long prefix    |
          before the text^     |
          {1:~         }{n: word    }{1: }|
          {1:~         }{n: choice  }{1: }|
          {1:~         }{12: text    }{1: }|
          {1:~         }{n: thing   }{1: }|
          {1:~                   }|
          {5:-- INSERT --}        |
        ]])
      end
    end)

    it('with VimResized autocmd', function()
      feed('isome long prefix before the ')
      command('set completeopt+=noinsert,noselect')
      command('autocmd VimResized * redraw!')
      command('set linebreak')
      fn.complete(29, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
            some long prefix before the ^    |
            {1:~                               }|*18
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {n: word  }|
            {n: choice}|
            {n: text  }|
            {n: thing }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 25, false, 100, 1, 1, 25 } },
        })
      else
        screen:expect([[
          some long prefix before the ^    |
          {1:~                        }{n: word  }|
          {1:~                        }{n: choice}|
          {1:~                        }{n: text  }|
          {1:~                        }{n: thing }|
          {1:~                               }|*14
          {5:-- INSERT --}                    |
        ]])
      end

      screen:try_resize(16, 10)
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:----------------]|*9
            [3:----------------]|
          ## grid 2
            some long       |
            prefix before   |
            the ^            |
            {1:~               }|*6
          ## grid 3
            {5:-- INSERT --}    |
          ## grid 4
            {n: word        }|
            {n: choice      }|
            {n: text        }|
            {n: thing       }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 3, false, 100, 1, 3, 3 } },
        })
      else
        screen:expect([[
          some long       |
          prefix before   |
          the ^            |
          {1:~  }{n: word        }|
          {1:~  }{n: choice      }|
          {1:~  }{n: text        }|
          {1:~  }{n: thing       }|
          {1:~               }|*2
          {5:-- INSERT --}    |
        ]])
      end
    end)

    it('with rightleft window', function()
      command('set rl wildoptions+=pum')
      feed('isome rightleft ')
      if multigrid then
        screen:expect([[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                            ^  tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            {5:-- INSERT --}                    |
        ]])
      else
        screen:expect([[
                          ^  tfelthgir emos|
          {1:                               ~}|*18
          {5:-- INSERT --}                    |
        ]])
      end

      command('set completeopt+=noinsert,noselect')
      fn.complete(16, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                            ^  tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {n:           drow }|
            {n:         eciohc }|
            {n:           txet }|
            {n:          gniht }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 2, false, 100, 1, 1, 2 } },
        })
      else
        screen:expect([[
                          ^  tfelthgir emos|
          {1:  }{n:           drow }{1:             ~}|
          {1:  }{n:         eciohc }{1:             ~}|
          {1:  }{n:           txet }{1:             ~}|
          {1:  }{n:          gniht }{1:             ~}|
          {1:                               ~}|*14
          {5:-- INSERT --}                    |
        ]])
      end

      feed('<c-n>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                        ^ drow tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            {5:-- INSERT --}                    |
          ## grid 4
            {12:           drow }|
            {n:         eciohc }|
            {n:           txet }|
            {n:          gniht }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 2, false, 100, 1, 1, 2 } },
        })
      else
        screen:expect([[
                      ^ drow tfelthgir emos|
          {1:  }{12:           drow }{1:             ~}|
          {1:  }{n:         eciohc }{1:             ~}|
          {1:  }{n:           txet }{1:             ~}|
          {1:  }{n:          gniht }{1:             ~}|
          {1:                               ~}|*14
          {5:-- INSERT --}                    |
        ]])
      end

      feed('<c-y>')
      if multigrid then
        screen:expect([[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                        ^ drow tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            {5:-- INSERT --}                    |
        ]])
      else
        screen:expect([[
                      ^ drow tfelthgir emos|
          {1:                               ~}|*18
          {5:-- INSERT --}                    |
        ]])
      end

      -- not rightleft on the cmdline
      feed('<esc>:sign ')
      if multigrid then
        screen:expect([[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                         drow tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            :sign ^                          |
        ]])
      else
        screen:expect([[
                       drow tfelthgir emos|
          {1:                               ~}|*18
          :sign ^                          |
        ]])
      end

      -- oldtest: Test_wildmenu_pum_rightleft()
      feed('<tab>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------]|*19
            [3:--------------------------------]|
          ## grid 2
                         drow tfelthgir emos|
            {1:                               ~}|*18
          ## grid 3
            :sign define^                    |
          ## grid 4
            {12: define         }|
            {n: jump           }|
            {n: list           }|
            {n: place          }|
            {n: undefine       }|
            {n: unplace        }|
          ]],
          float_pos = { [4] = { -1, 'SW', 1, 19, 5, false, 250, 2, 13, 5 } },
        })
      else
        screen:expect([[
                       drow tfelthgir emos|
          {1:                               ~}|*12
          {1:     }{12: define         }{1:          ~}|
          {1:     }{n: jump           }{1:          ~}|
          {1:     }{n: list           }{1:          ~}|
          {1:     }{n: place          }{1:          ~}|
          {1:     }{n: undefine       }{1:          ~}|
          {1:     }{n: unplace        }{1:          ~}|
          :sign define^                    |
        ]])
      end
    end)

    it('with rightleft vsplits', function()
      screen:try_resize(40, 6)
      command('set rightleft')
      command('rightbelow vsplit')
      command('set completeopt+=noinsert,noselect')
      command('set pumheight=2')
      feed('isome rightleft ')
      fn.complete(16, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:-------------------]│[4:--------------------]|*4
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          [3:----------------------------------------]|
        ## grid 2
               tfelthgir emos|
          {1:                  ~}|*3
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
              ^  tfelthgir emos|
          {1:                   ~}|*3
        ## grid 5
          {c: }{n:           drow }|
          {12: }{n:         eciohc }|
        ]],
          float_pos = { [5] = { -1, 'NW', 4, 1, -11, false, 100, 1, 1, 9 } },
        }
      else
        screen:expect([[
               tfelthgir emos│    ^  tfelthgir emos|
          {1:         }{c: }{n:           drow }{1:             ~}|
          {1:         }{12: }{n:         eciohc }{1:             ~}|
          {1:                  ~}│{1:                   ~}|
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          {5:-- INSERT --}                            |
        ]])
      end
      feed('<C-E><CR>')
      fn.complete(1, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:-------------------]│[4:--------------------]|*4
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          [3:----------------------------------------]|
        ## grid 2
               tfelthgir emos|
                             |
          {1:                  ~}|*2
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
                tfelthgir emos|
                             ^ |
          {1:                   ~}|*2
        ## grid 5
          {c: }{n:           drow}|
          {12: }{n:         eciohc}|
        ]],
          float_pos = { [5] = { -1, 'NW', 4, 2, 4, false, 100, 1, 2, 24 } },
        }
      else
        screen:expect([[
               tfelthgir emos│      tfelthgir emos|
                             │                   ^ |
          {1:                  ~}│{1:    }{c: }{n:           drow}|
          {1:                  ~}│{1:    }{12: }{n:         eciohc}|
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          {5:-- INSERT --}                            |
        ]])
      end
      feed('<C-E>')
      async_meths.nvim_call_function('input', { '', '', 'sign' })
      if multigrid then
        screen:expect([[
        ## grid 1
          [2:-------------------]│[4:--------------------]|*4
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          [3:----------------------------------------]|
        ## grid 2
               tfelthgir emos|
                             |
          {1:                  ~}|*2
        ## grid 3
          ^                                        |
        ## grid 4
                tfelthgir emos|
                              |
          {1:                   ~}|*2
        ]])
      else
        screen:expect([[
               tfelthgir emos│      tfelthgir emos|
                             │                    |
          {1:                  ~}│{1:                   ~}|*2
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          ^                                        |
        ]])
      end
      command('set wildoptions+=pum')
      feed('<Tab>')
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:-------------------]│[4:--------------------]|*4
          {2:[No Name] [+]       }{3:[No Name] [+]       }|
          [3:----------------------------------------]|
        ## grid 2
               tfelthgir emos|
                             |
          {1:                  ~}|*2
        ## grid 3
          define^                                  |
        ## grid 4
                tfelthgir emos|
                              |
          {1:                   ~}|*2
        ## grid 5
          {12:define         }{c: }|
          {n:jump           }{12: }|
        ]],
          float_pos = { [5] = { -1, 'SW', 1, 5, 0, false, 250, 2, 3, 0 } },
        }
      else
        screen:expect([[
               tfelthgir emos│      tfelthgir emos|
                             │                    |
          {1:                  ~}│{1:                   ~}|
          {12:define         }{c: }{1:  ~}│{1:                   ~}|
          {n:jump           }{12: }{2:    }{3:[No Name] [+]       }|
          define^                                  |
        ]])
      end
    end)

    it('with multiline messages', function()
      screen:try_resize(40, 8)
      feed('ixx<cr>')
      command('imap <f2> <cmd>echoerr "very"\\|echoerr "much"\\|echoerr "error"<cr>')
      fn.complete(1, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:----------------------------------------]|*7
          [3:----------------------------------------]|
        ## grid 2
          xx                                      |
          word^                                    |
          {1:~                                       }|*5
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
          {12:word           }|
          {n:choice         }|
          {n:text           }|
          {n:thing          }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          word^                                    |
          {12:word           }{1:                         }|
          {n:choice         }{1:                         }|
          {n:text           }{1:                         }|
          {n:thing          }{1:                         }|
          {1:~                                       }|
          {5:-- INSERT --}                            |
        ]])
      end

      feed('<f2>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:----------------------------------------]|*4
          [3:----------------------------------------]|*4
        ## grid 2
          xx                                      |
          word                                    |
          {1:~                                       }|*5
        ## grid 3
          {9:very}                                    |
          {9:much}                                    |
          {9:error}                                   |
          {6:Press ENTER or type command to continue}^ |
        ## grid 4
          {12:word           }|
          {n:choice         }|
          {n:text           }|
          {n:thing          }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          word                                    |
          {12:word           }{1:                         }|
          {3:                                        }|
          {9:very}                                    |
          {9:much}                                    |
          {9:error}                                   |
          {6:Press ENTER or type command to continue}^ |
        ]])
      end

      feed('<cr>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:----------------------------------------]|*7
          [3:----------------------------------------]|
        ## grid 2
          xx                                      |
          word^                                    |
          {1:~                                       }|*5
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
          {12:word           }|
          {n:choice         }|
          {n:text           }|
          {n:thing          }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          word^                                    |
          {12:word           }{1:                         }|
          {n:choice         }{1:                         }|
          {n:text           }{1:                         }|
          {n:thing          }{1:                         }|
          {1:~                                       }|
          {5:-- INSERT --}                            |
        ]])
      end

      feed('<c-n>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:----------------------------------------]|*7
          [3:----------------------------------------]|
        ## grid 2
          xx                                      |
          choice^                                  |
          {1:~                                       }|*5
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
          {n:word           }|
          {12:choice         }|
          {n:text           }|
          {n:thing          }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          choice^                                  |
          {n:word           }{1:                         }|
          {12:choice         }{1:                         }|
          {n:text           }{1:                         }|
          {n:thing          }{1:                         }|
          {1:~                                       }|
          {5:-- INSERT --}                            |
        ]])
      end

      command('split')
      feed('<c-u>')
      fn.complete(1, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [5:----------------------------------------]|*3
          {3:[No Name] [+]                           }|
          [2:----------------------------------------]|*2
          {2:[No Name] [+]                           }|
          [3:----------------------------------------]|
        ## grid 2
          xx                                      |
          word                                    |
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
          {12:word           }|
          {n:choice         }|
          {n:text           }|
          {n:thing          }|
        ## grid 5
          xx                                      |
          word^                                    |
          {1:~                                       }|
        ]],
          float_pos = { [4] = { -1, 'NW', 5, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          word^                                    |
          {12:word           }{1:                         }|
          {n:choice         }{3:                         }|
          {n:text           }                         |
          {n:thing          }                         |
          {2:[No Name] [+]                           }|
          {5:-- INSERT --}                            |
        ]])
      end

      api.nvim_input_mouse('wheel', 'down', '', 0, 6, 15)
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [5:----------------------------------------]|*3
          {3:[No Name] [+]                           }|
          [2:----------------------------------------]|*2
          {2:[No Name] [+]                           }|
          [3:----------------------------------------]|
        ## grid 2
          word                                    |
          {1:~                                       }|
        ## grid 3
          {5:-- INSERT --}                            |
        ## grid 4
          {12:word           }|
          {n:choice         }|
          {n:text           }|
          {n:thing          }|
        ## grid 5
          xx                                      |
          word^                                    |
          {1:~                                       }|
        ]],
          float_pos = { [4] = { -1, 'NW', 5, 2, 0, false, 100, 1, 2, 0 } },
        })
      else
        screen:expect([[
          xx                                      |
          word^                                    |
          {12:word           }{1:                         }|
          {n:choice         }{3:                         }|
          {n:text           }                         |
          {n:thing          }{1:                         }|
          {2:[No Name] [+]                           }|
          {5:-- INSERT --}                            |
        ]])
      end
    end)

    if not multigrid then
      it('with kind, menu and abbr attributes', function()
        screen:try_resize(40, 8)
        feed('ixx ')
        fn.complete(4, {
          { word = 'wordey', kind = 'x', menu = 'extrainfo' },
          'thing',
          { word = 'secret', abbr = 'sneaky', menu = 'bar' },
        })
        screen:expect([[
          xx wordey^                               |
          {1:~ }{12: wordey x extrainfo }{1:                  }|
          {1:~ }{n: thing              }{1:                  }|
          {1:~ }{n: sneaky   bar       }{1:                  }|
          {1:~                                       }|*3
          {5:-- INSERT --}                            |
        ]])

        feed('<c-p>')
        screen:expect([[
          xx ^                                     |
          {1:~ }{n: wordey x extrainfo }{1:                  }|
          {1:~ }{n: thing              }{1:                  }|
          {1:~ }{n: sneaky   bar       }{1:                  }|
          {1:~                                       }|*3
          {5:-- INSERT --}                            |
        ]])

        feed('<c-p>')
        screen:expect([[
          xx secret^                               |
          {1:~ }{n: wordey x extrainfo }{1:                  }|
          {1:~ }{n: thing              }{1:                  }|
          {1:~ }{12: sneaky   bar       }{1:                  }|
          {1:~                                       }|*3
          {5:-- INSERT --}                            |
        ]])

        feed('<esc>')
        screen:expect([[
          xx secre^t                               |
          {1:~                                       }|*6
                                                  |
        ]])
      end)

      it('wildoptions=pum', function()
        screen:try_resize(32, 10)
        command('set wildmenu')
        command('set wildoptions=pum')
        command('set shellslash')
        command('cd test/functional/fixtures/wildpum')

        feed(':sign ')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign ^                          |
        ]])

        feed('<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{12: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign define^                    |
        ]])

        feed('<Right><Right>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{12: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign list^                      |
        ]])

        feed('<C-N>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{12: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign place^                     |
        ]])

        feed('<C-P>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{12: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign list^                      |
        ]])

        feed('<Left>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{12: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign jump^                      |
        ]])

        -- pressing <C-E> should end completion and go back to the original match
        feed('<C-E>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign ^                          |
        ]])

        -- pressing <C-Y> should select the current match and end completion
        feed('<Tab><C-P><C-P><C-Y>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign unplace^                   |
        ]])

        -- showing popup menu in different columns in the cmdline
        feed('<C-U>sign define <Tab>')
        screen:expect([[
                                          |
          {1:~                               }|
          {1:~           }{12: culhl=         }{1:    }|
          {1:~           }{n: icon=          }{1:    }|
          {1:~           }{n: linehl=        }{1:    }|
          {1:~           }{n: numhl=         }{1:    }|
          {1:~           }{n: priority=      }{1:    }|
          {1:~           }{n: text=          }{1:    }|
          {1:~           }{n: texthl=        }{1:    }|
          :sign define culhl=^             |
        ]])

        feed('<Space><Tab>')
        screen:expect([[
                                          |
          {1:~                               }|
          {1:~                  }{12: culhl=     }{1: }|
          {1:~                  }{n: icon=      }{1: }|
          {1:~                  }{n: linehl=    }{1: }|
          {1:~                  }{n: numhl=     }{1: }|
          {1:~                  }{n: priority=  }{1: }|
          {1:~                  }{n: text=      }{1: }|
          {1:~                  }{n: texthl=    }{1: }|
          :sign define culhl= culhl=^      |
        ]])

        feed('<C-U>e Xnamedi<Tab><Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {1:~          }{12: XdirA/         }{1:     }|
          {1:~          }{n: XfileA         }{1:     }|
          :e Xnamedir/XdirA/^              |
        ]])

        -- Pressing <Down> on a directory name should go into that directory
        feed('<Down>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {1:~                }{12: XdirB/       }{1: }|
          {1:~                }{n: XfileB       }{1: }|
          :e Xnamedir/XdirA/XdirB/^        |
        ]])

        -- Pressing <Up> on a directory name should go to the parent directory
        feed('<Up>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {1:~          }{12: XdirA/         }{1:     }|
          {1:~          }{n: XfileA         }{1:     }|
          :e Xnamedir/XdirA/^              |
        ]])

        -- Pressing <C-A> when the popup menu is displayed should list all the
        -- matches and remove the popup menu
        feed(':<C-U>sign <Tab><C-A>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {3:                                }|
          :sign define jump list place und|
          efine unplace^                   |
        ]])

        -- Pressing <Left> after that should move the cursor
        feed('<Left>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {3:                                }|
          :sign define jump list place und|
          efine unplac^e                   |
        ]])
        feed('<End>')

        -- Pressing <C-D> when the popup menu is displayed should remove the popup
        -- menu
        feed('<C-U>sign <Tab><C-D>')
        screen:expect([[
                                          |
          {1:~                               }|*5
          {3:                                }|
          :sign define                    |
          define                          |
          :sign define^                    |
        ]])

        -- Pressing <S-Tab> should open the popup menu with the last entry selected
        feed('<C-U><CR>:sign <S-Tab><C-P>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{12: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign undefine^                  |
        ]])

        -- Pressing <Esc> should close the popup menu and cancel the cmd line
        feed('<C-U><CR>:sign <Tab><Esc>')
        screen:expect([[
          ^                                |
          {1:~                               }|*8
                                          |
        ]])

        -- Typing a character when the popup is open, should close the popup
        feed(':sign <Tab>x')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign definex^                   |
        ]])

        -- When the popup is open, entering the cmdline window should close the popup
        feed('<C-U>sign <Tab><C-F>')
        screen:expect([[
                                          |
          {2:[No Name]                       }|
          {1::}sign define                    |
          {1::}sign define^                    |
          {1:~                               }|*4
          {3:[Command Line]                  }|
          :sign define                    |
        ]])
        feed(':q<CR>')

        -- After the last popup menu item, <C-N> should show the original string
        feed(':sign u<Tab><C-N><C-N>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign u^                         |
        ]])

        -- Use the popup menu for the command name
        feed('<C-U>bu<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*4
          {12: bufdo          }{1:                }|
          {n: buffer         }{1:                }|
          {n: buffers        }{1:                }|
          {n: bunload        }{1:                }|
          :bufdo^                          |
        ]])

        -- Pressing <BS> should remove the popup menu and erase the last character
        feed('<C-E><C-U>sign <Tab><BS>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign defin^                     |
        ]])

        -- Pressing <C-W> should remove the popup menu and erase the previous word
        feed('<C-E><C-U>sign <Tab><C-W>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign ^                          |
        ]])

        -- Pressing <C-U> should remove the popup menu and erase the entire line
        feed('<C-E><C-U>sign <Tab><C-U>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :^                               |
        ]])

        -- Using <C-E> to cancel the popup menu and then pressing <Up> should recall
        -- the cmdline from history
        feed('sign xyz<Esc>:sign <Tab><C-E><Up>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :sign xyz^                       |
        ]])

        feed('<esc>')

        -- Check "list" still works
        command('set wildmode=longest,list')
        feed(':cn<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*3
          {3:                                }|
          :cn                             |
          cnewer       cnoreabbrev        |
          cnext        cnoremap           |
          cnfile       cnoremenu          |
          :cn^                             |
        ]])
        feed('s')
        screen:expect([[
                                          |
          {1:~                               }|*3
          {3:                                }|
          :cn                             |
          cnewer       cnoreabbrev        |
          cnext        cnoremap           |
          cnfile       cnoremenu          |
          :cns^                            |
        ]])

        feed('<esc>')
        command('set wildmode=full')

        -- Tests a directory name contained full-width characters.
        feed(':e あいう/<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*5
          {1:~        }{12: 123            }{1:       }|
          {1:~        }{n: abc            }{1:       }|
          {1:~        }{n: xyz            }{1:       }|
          :e あいう/123^                   |
        ]])
        feed('<Esc>')

        -- Pressing <PageDown> should scroll the menu downward
        feed(':sign <Tab><PageDown>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{12: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign undefine^                  |
        ]])
        feed('<PageDown>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{12: unplace        }{1:           }|
          :sign unplace^                   |
        ]])
        feed('<PageDown>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign ^                          |
        ]])
        feed('<PageDown>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{12: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign define^                    |
        ]])
        feed('<C-U>sign <Tab><Right><Right><PageDown>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{12: unplace        }{1:           }|
          :sign unplace^                   |
        ]])

        -- Pressing <PageUp> should scroll the menu upward
        feed('<C-U>sign <Tab><PageUp>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign ^                          |
        ]])
        feed('<PageUp>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{12: unplace        }{1:           }|
          :sign unplace^                   |
        ]])
        feed('<PageUp>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{n: define         }{1:           }|
          {1:~    }{12: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign jump^                      |
        ]])
        feed('<PageUp>')
        screen:expect([[
                                          |
          {1:~                               }|*2
          {1:~    }{12: define         }{1:           }|
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign define^                    |
        ]])

        -- pressing <C-E> to end completion should work in middle of the line too
        feed('<Esc>:set wildchazz<Left><Left><Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*6
          {1:~   }{12: wildchar       }{1:            }|
          {1:~   }{n: wildcharm      }{1:            }|
          :set wildchar^zz                 |
        ]])
        feed('<C-E>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :set wildcha^zz                  |
        ]])

        -- pressing <C-Y> should select the current match and end completion
        feed('<Esc>:set wildchazz<Left><Left><Tab><C-Y>')
        screen:expect([[
                                          |
          {1:~                               }|*8
          :set wildchar^zz                 |
        ]])

        feed('<Esc>')

        -- check positioning with multibyte char in pattern
        command('e långfile1')
        command('sp långfile2')
        feed(':b lå<tab>')
        screen:expect([[
                                          |
          {1:~                               }|*3
          {3:långfile2                       }|
                                          |
          {1:~                               }|
          {1:~ }{12: långfile1      }{1:              }|
          {2:lå}{n: långfile2      }{2:              }|
          :b långfile1^                    |
        ]])

        -- check doesn't crash on screen resize
        screen:try_resize(20, 6)
        screen:expect([[
                              |
          {1:~                   }|
          {3:långfile2           }|
            {12: långfile1      }  |
          {2:lå}{n: långfile2      }{2:  }|
          :b långfile1^        |
        ]])

        screen:try_resize(50, 15)
        screen:expect([[
                                                            |
          {1:~                                                 }|
          {3:långfile2                                         }|
                                                            |
          {1:~                                                 }|*8
          {1:~ }{12: långfile1      }{1:                                }|
          {2:lå}{n: långfile2      }{2:                                }|
          :b långfile1^                                      |
        ]])

        -- position is calculated correctly with "longest"
        feed('<esc>')
        command('set wildmode=longest:full,full')
        feed(':b lå<tab>')
        screen:expect([[
                                                            |
          {1:~                                                 }|
          {3:långfile2                                         }|
                                                            |
          {1:~                                                 }|*8
          {1:~ }{n: långfile1      }{1:                                }|
          {2:lå}{n: långfile2      }{2:                                }|
          :b långfile^                                       |
        ]])

        feed('<esc>')
        command('close')
        command('set wildmode=full')

        -- special case: when patterns ends with "/", show menu items aligned
        -- after the "/"
        feed(':e compdir/<tab>')
        screen:expect([[
                                                            |
          {1:~                                                 }|*11
          {1:~         }{12: file1          }{1:                        }|
          {1:~         }{n: file2          }{1:                        }|
          :e compdir/file1^                                  |
        ]])
      end)
    end

    it('wildoptions=pum with scrolled messages', function()
      screen:try_resize(40, 10)
      command('set wildmenu')
      command('set wildoptions=pum')

      feed(':echoerr "fail"|echoerr "error"<cr>')
      if multigrid then
        screen:expect([[
          ## grid 1
            [2:----------------------------------------]|*7
            [3:----------------------------------------]|*3
          ## grid 2
                                                    |
            {1:~                                       }|*8
          ## grid 3
            {9:fail}                                    |
            {9:error}                                   |
            {6:Press ENTER or type command to continue}^ |
        ]])
      else
        screen:expect([[
                                                  |
          {1:~                                       }|*5
          {3:                                        }|
          {9:fail}                                    |
          {9:error}                                   |
          {6:Press ENTER or type command to continue}^ |
        ]])
      end

      feed(':sign <tab>')
      if multigrid then
        screen:expect({
          grid = [[
          ## grid 1
            [2:----------------------------------------]|*7
            [3:----------------------------------------]|*3
          ## grid 2
                                                    |
            {1:~                                       }|*8
          ## grid 3
            {9:fail}                                    |
            {9:error}                                   |
            :sign define^                            |
          ## grid 4
            {12: define         }|
            {n: jump           }|
            {n: list           }|
            {n: place          }|
            {n: undefine       }|
            {n: unplace        }|
          ]],
          float_pos = { [4] = { -1, 'SW', 1, 9, 5, false, 250, 2, 3, 5 } },
        })
      else
        screen:expect([[
                                                  |
          {1:~                                       }|*2
          {1:~    }{12: define         }{1:                   }|
          {1:~    }{n: jump           }{1:                   }|
          {1:~    }{n: list           }{1:                   }|
          {3:     }{n: place          }{3:                   }|
          {9:fail} {n: undefine       }                   |
          {9:error}{n: unplace        }                   |
          :sign define^                            |
        ]])
      end

      feed('d')
      if multigrid then
        screen:expect([[
          ## grid 1
            [2:----------------------------------------]|*7
            [3:----------------------------------------]|*3
          ## grid 2
                                                    |
            {1:~                                       }|*8
          ## grid 3
            {9:fail}                                    |
            {9:error}                                   |
            :sign defined^                           |
        ]])
      else
        screen:expect([[
                                                  |
          {1:~                                       }|*5
          {3:                                        }|
          {9:fail}                                    |
          {9:error}                                   |
          :sign defined^                           |
        ]])
      end
    end)

    if not multigrid then
      it('wildoptions=pum and wildmode=longest,full #11622', function()
        screen:try_resize(30, 8)
        command('set wildmenu')
        command('set wildoptions=pum')
        command('set wildmode=longest,full')

        -- With 'wildmode' set to 'longest,full', completing a match should display
        -- the longest match, the wildmenu should not be displayed.
        feed(':sign u<Tab>')
        screen:expect([[
                                        |
          {1:~                             }|*6
          :sign un^                      |
        ]])
        eq(0, fn.wildmenumode())

        -- pressing <Tab> should display the wildmenu
        feed('<Tab>')
        screen:expect([[
                                        |
          {1:~                             }|*4
          {1:~    }{12: undefine       }{1:         }|
          {1:~    }{n: unplace        }{1:         }|
          :sign undefine^                |
        ]])
        eq(1, fn.wildmenumode())

        -- pressing <Tab> second time should select the next entry in the menu
        feed('<Tab>')
        screen:expect([[
                                        |
          {1:~                             }|*4
          {1:~    }{n: undefine       }{1:         }|
          {1:~    }{12: unplace        }{1:         }|
          :sign unplace^                 |
        ]])
      end)

      it('wildoptions=pum with a wrapped line in buffer vim-patch:8.2.4655', function()
        screen:try_resize(32, 10)
        api.nvim_buf_set_lines(0, 0, -1, true, { ('a'):rep(100) })
        command('set wildoptions+=pum')
        feed('$')
        feed(':sign <Tab>')
        screen:expect([[
          aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa|*3
          aaaa {12: define         }           |
          {1:~    }{n: jump           }{1:           }|
          {1:~    }{n: list           }{1:           }|
          {1:~    }{n: place          }{1:           }|
          {1:~    }{n: undefine       }{1:           }|
          {1:~    }{n: unplace        }{1:           }|
          :sign define^                    |
        ]])
      end)

      -- oldtest: Test_wildmenu_pum_odd_wildchar()
      it('wildoptions=pum with odd wildchar', function()
        screen:try_resize(30, 10)
        -- Test odd wildchar interactions with pum. Make sure they behave properly
        -- and don't lead to memory corruption due to improperly cleaned up memory.
        exec([[
          set wildoptions=pum
          set wildchar=<C-E>
        ]])

        feed(':sign <C-E>')
        screen:expect([[
                                        |
          {1:~                             }|*2
          {1:~    }{12: define         }{1:         }|
          {1:~    }{n: jump           }{1:         }|
          {1:~    }{n: list           }{1:         }|
          {1:~    }{n: place          }{1:         }|
          {1:~    }{n: undefine       }{1:         }|
          {1:~    }{n: unplace        }{1:         }|
          :sign define^                  |
        ]])

        -- <C-E> being a wildchar takes priority over its original functionality
        feed('<C-E>')
        screen:expect([[
                                        |
          {1:~                             }|*2
          {1:~    }{n: define         }{1:         }|
          {1:~    }{12: jump           }{1:         }|
          {1:~    }{n: list           }{1:         }|
          {1:~    }{n: place          }{1:         }|
          {1:~    }{n: undefine       }{1:         }|
          {1:~    }{n: unplace        }{1:         }|
          :sign jump^                    |
        ]])

        feed('<Esc>')
        screen:expect([[
          ^                              |
          {1:~                             }|*8
                                        |
        ]])

        -- Escape key can be wildchar too. Double-<Esc> is hard-coded to escape
        -- command-line, and we need to make sure to clean up properly.
        command('set wildchar=<Esc>')
        feed(':sign <Esc>')
        screen:expect([[
                                        |
          {1:~                             }|*2
          {1:~    }{12: define         }{1:         }|
          {1:~    }{n: jump           }{1:         }|
          {1:~    }{n: list           }{1:         }|
          {1:~    }{n: place          }{1:         }|
          {1:~    }{n: undefine       }{1:         }|
          {1:~    }{n: unplace        }{1:         }|
          :sign define^                  |
        ]])

        feed('<Esc>')
        screen:expect([[
          ^                              |
          {1:~                             }|*8
                                        |
        ]])

        -- <C-\> can also be wildchar. <C-\><C-N> however will still escape cmdline
        -- and we again need to make sure we clean up properly.
        command([[set wildchar=<C-\>]])
        feed([[:sign <C-\><C-\>]])
        screen:expect([[
                                        |
          {1:~                             }|*2
          {1:~    }{12: define         }{1:         }|
          {1:~    }{n: jump           }{1:         }|
          {1:~    }{n: list           }{1:         }|
          {1:~    }{n: place          }{1:         }|
          {1:~    }{n: undefine       }{1:         }|
          {1:~    }{n: unplace        }{1:         }|
          :sign define^                  |
        ]])

        feed('<C-N>')
        screen:expect([[
          ^                              |
          {1:~                             }|*8
                                        |
        ]])
      end)

      -- oldtest: Test_wildmenu_pum_hl_match()
      it('highlighting matched text in cmdline pum', function()
        exec([[
          set wildoptions=pum,fuzzy
          hi PmenuMatchSel  guifg=Blue guibg=Grey
          hi PmenuMatch     guifg=Blue guibg=Plum1
        ]])

        feed(':sign plc<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{12: }{ms:pl}{12:a}{ms:c}{12:e          }{1:           }|
          {1:~    }{n: un}{mn:pl}{n:a}{mn:c}{n:e        }{1:           }|
          :sign place^                     |
        ]])
        feed('<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{n: }{mn:pl}{n:a}{mn:c}{n:e          }{1:           }|
          {1:~    }{12: un}{ms:pl}{12:a}{ms:c}{12:e        }{1:           }|
          :sign unplace^                   |
        ]])
        feed('<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{n: }{mn:pl}{n:a}{mn:c}{n:e          }{1:           }|
          {1:~    }{n: un}{mn:pl}{n:a}{mn:c}{n:e        }{1:           }|
          :sign plc^                       |
        ]])
        feed('<Esc>')
        command('set wildoptions-=fuzzy')
        feed(':sign un<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{12: }{ms:un}{12:define       }{1:           }|
          {1:~    }{n: }{mn:un}{n:place        }{1:           }|
          :sign undefine^                  |
        ]])
        feed('<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{n: }{mn:un}{n:define       }{1:           }|
          {1:~    }{12: }{ms:un}{12:place        }{1:           }|
          :sign unplace^                   |
        ]])
        feed('<Tab>')
        screen:expect([[
                                          |
          {1:~                               }|*16
          {1:~    }{n: }{mn:un}{n:define       }{1:           }|
          {1:~    }{n: }{mn:un}{n:place        }{1:           }|
          :sign un^                        |
        ]])
      end)

      -- oldtest: Test_wildmenu_pum_hl_nonfirst()
      it('highlight matched text in the middle in cmdline pum', function()
        exec([[
          set wildoptions=pum wildchar=<tab> wildmode=noselect,full
          hi PmenuMatchSel  guifg=Blue guibg=Grey
          hi PmenuMatch     guifg=Blue guibg=Plum1
          func T(a, c, p)
            return ["oneA", "o neBneB", "aoneC"]
          endfunc
          command -nargs=1 -complete=customlist,T MyCmd
        ]])

        feed(':MyCmd ne<tab>')
        screen:expect([[
                                          |
          {1:~                               }|*15
          {1:~     }{n: o}{mn:ne}{n:A           }{1:          }|
          {1:~     }{n: o }{mn:ne}{n:BneB       }{1:          }|
          {1:~     }{n: ao}{mn:ne}{n:C          }{1:          }|
          :MyCmd ne^                       |
        ]])
      end)

      -- oldtest: Test_pum_scroll_noselect()
      it('cmdline pum does not retain scroll position with "noselect"', function()
        screen:try_resize(32, 10)
        exec([[
          command! -nargs=* -complete=customlist,TestFn TestCmd echo
          func TestFn(a, b, c)
            return map(range(1, 50), 'printf("a%d", v:val)')
          endfunc
          set wildmode=noselect,full
          set wildoptions=pum
          set wildmenu
          set noruler
        ]])

        feed(':TestCmd <tab>' .. ('<c-n>'):rep(20))
        screen:expect([[
                  {n: a15            }{12: }       |
          {1:~       }{n: a16            }{12: }{1:       }|
          {1:~       }{n: a17            }{12: }{1:       }|
          {1:~       }{n: a18            }{c: }{1:       }|
          {1:~       }{n: a19            }{12: }{1:       }|
          {1:~       }{12: a20             }{1:       }|
          {1:~       }{n: a21            }{12: }{1:       }|
          {1:~       }{n: a22            }{12: }{1:       }|
          {1:~       }{n: a23            }{12: }{1:       }|
          :TestCmd a20^                    |
        ]])

        feed('<esc>:TestCmd <tab>')
        screen:expect([[
                  {n: a1             }{c: }       |
          {1:~       }{n: a2             }{12: }{1:       }|
          {1:~       }{n: a3             }{12: }{1:       }|
          {1:~       }{n: a4             }{12: }{1:       }|
          {1:~       }{n: a5             }{12: }{1:       }|
          {1:~       }{n: a6             }{12: }{1:       }|
          {1:~       }{n: a7             }{12: }{1:       }|
          {1:~       }{n: a8             }{12: }{1:       }|
          {1:~       }{n: a9             }{12: }{1:       }|
          :TestCmd ^                       |
        ]])
      end)

      it(
        'cascading highlights for matched text (PmenuMatch, PmenuMatchSel) in cmdline pum',
        function()
          exec([[
            set wildoptions=pum,fuzzy
            hi Pmenu          guifg=White guibg=Grey gui=underline,italic
            hi PmenuSel       guifg=Red gui=strikethrough
            hi PmenuMatch     guifg=Yellow guibg=Pink gui=bold
            hi PmenuMatchSel  guifg=Black guibg=White
          ]])

          feed(':sign plc<Tab>')
          screen:expect([[
                                            |
            {1:~                               }|*16
            {1:~    }{106: }{107:pl}{106:a}{107:c}{106:e          }{1:           }|
            {1:~    }{108: un}{109:pl}{108:a}{109:c}{108:e        }{1:           }|
            :sign place^                     |
          ]])
        end
      )
    end

    it("'pumheight'", function()
      screen:try_resize(32, 8)
      feed('isome long prefix before the ')
      command('set completeopt+=noinsert,noselect')
      command('set linebreak')
      command('set pumheight=2')
      fn.complete(29, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
          some long prefix before the ^    |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: word  }{c: }|
          {n: choice}{12: }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 24, false, 100, 1, 1, 24 } },
        }
      else
        screen:expect([[
          some long prefix before the ^    |
          {1:~                       }{n: word  }{c: }|
          {1:~                       }{n: choice}{12: }|
          {1:~                               }|*4
          {5:-- INSERT --}                    |
        ]])
      end
    end)

    it("'pumwidth'", function()
      screen:try_resize(32, 8)
      feed('isome long prefix before the ')
      command('set completeopt+=noinsert,noselect')
      command('set linebreak')
      command('set pumwidth=8')
      fn.complete(29, { 'word', 'choice', 'text', 'thing' })
      if multigrid then
        screen:expect {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
          some long prefix before the ^    |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: word  }|
          {n: choice}|
          {n: text  }|
          {n: thing }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 25, false, 100, 1, 1, 25 } },
        }
      else
        screen:expect([[
          some long prefix before the ^    |
          {1:~                        }{n: word  }|
          {1:~                        }{n: choice}|
          {1:~                        }{n: text  }|
          {1:~                        }{n: thing }|
          {1:~                               }|*2
          {5:-- INSERT --}                    |
        ]])
      end
    end)

    -- oldtest: Test_pum_maxwidth()
    it("'pummaxwidth'", function()
      screen:try_resize(60, 8)
      api.nvim_buf_set_lines(0, 0, -1, true, {
        '123456789_123456789_123456789_a',
        '123456789_123456789_123456789_b',
        '            123',
      })
      feed('G"zyy')
      feed('A<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~                                                           }|*4
        ## grid 3
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ## grid 4
          {12: 123456789_123456789_123456789_a }|
          {n: 123456789_123456789_123456789_b }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 11, false, 100, 1, 3, 11 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~          }{12: 123456789_123456789_123456789_a }{1:                }|
          {1:~          }{n: 123456789_123456789_123456789_b }{1:                }|
          {1:~                                                           }|*2
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ]])
      end
      feed('<Esc>3Gdd"zp')

      command('set pummaxwidth=10')
      feed('GA<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~                                                           }|*4
        ## grid 3
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ## grid 4
          {12: 123456789>}|
          {n: 123456789>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 11, false, 100, 1, 3, 11 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~          }{12: 123456789>}{1:                                      }|
          {1:~          }{n: 123456789>}{1:                                      }|
          {1:~                                                           }|*2
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ]])
      end
      feed('<Esc>3Gdd"zp')

      command('set pummaxwidth=20')
      feed('GA<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~                                                           }|*4
        ## grid 3
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ## grid 4
          {12: 123456789_123456789>}|
          {n: 123456789_123456789>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 11, false, 100, 1, 3, 11 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~          }{12: 123456789_123456789>}{1:                            }|
          {1:~          }{n: 123456789_123456789>}{1:                            }|
          {1:~                                                           }|*2
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ]])
      end
      feed('<Esc>3Gdd"zp')

      command('set pumwidth=20 pummaxwidth=8')
      feed('GA<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~                                                           }|*4
        ## grid 3
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ## grid 4
          {12: 1234567>}|
          {n: 1234567>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 11, false, 100, 1, 3, 11 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_a                             |
          123456789_123456789_123456789_b                             |
                      123456789_123456789_123456789_a^                 |
          {1:~          }{12: 1234567>}{1:                                        }|
          {1:~          }{n: 1234567>}{1:                                        }|
          {1:~                                                           }|*2
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}             |
        ]])
      end
      feed('<Esc>3Gdd"zp')

      screen:try_resize(32, 10)
      feed('GA<C-X><C-N>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*9
          [3:--------------------------------]|
        ## grid 2
          123456789_123456789_123456789_a |
          123456789_123456789_123456789_b |
                      123456789_123456789_|
          123456789_a^                     |
          {1:~                               }|*5
        ## grid 3
          {5:-- }{6:match 1 of 2}                 |
        ## grid 4
          {12: 1234567>}|
          {n: 1234567>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 4, 11, false, 100, 1, 4, 11 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_a |
          123456789_123456789_123456789_b |
                      123456789_123456789_|
          123456789_a^                     |
          {1:~          }{12: 1234567>}{1:            }|
          {1:~          }{n: 1234567>}{1:            }|
          {1:~                               }|*3
          {5:-- }{6:match 1 of 2}                 |
        ]])
      end
      feed('<Esc>3Gdd"zp')
    end)

    -- oldtest: Test_pum_maxwidth_multibyte()
    it("'pummaxwidth' with multibyte", function()
      screen:try_resize(60, 8)
      exec([[
        hi StrikeFake guifg=DarkRed
        let g:change = 0
        func Omni_test(findstart, base)
          if a:findstart
            return col(".")
          endif
          if g:change == 0
            return [
              \ #{word: "123456789_123456789_123456789_"},
              \ #{word: "一二三四五六七八九十"},
              \ #{word: "abcdefghij"},
              \ #{word: "上下左右"},
              \ ]
          elseif g:change == 1
            return [
              \ #{word: "foo", menu: "fooMenu", kind: "fooKind"},
              \ #{word: "bar", menu: "barMenu", kind: "barKind"},
              \ #{word: "baz", menu: "bazMenu", kind: "bazKind"},
              \ ]
          elseif g:change == 2
            return [
              \ #{word: "foo", menu: "fooMenu", kind: "fooKind"},
              \ #{word: "bar", menu: "fooMenu", kind: "一二三四"},
              \ #{word: "一二三四五", kind: "multi"},
              \ ]
            return [#{word: "bar", menu: "fooMenu", kind: "一二三"}]
          elseif g:change == 3
            return [#{word: "bar", menu: "fooMenu", kind: "一二三"}]
          else
            return [
              \ #{word: "一二三四五六七八九十", abbr_hlgroup: "StrikeFake"},
              \ #{word: "123456789_123456789_123456789_", abbr_hlgroup: "StrikeFake"},
              \ ]
          endif
        endfunc
        set omnifunc=Omni_test
        set cot+=menuone
      ]])

      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_^                              |
          {1:~                                                           }|*6
        ## grid 3
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ## grid 4
          {12:123456789_123456789_123456789_ }|
          {n:一二三四五六七八九十           }|
          {n:abcdefghij                     }|
          {n:上下左右                       }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_^                              |
          {12:123456789_123456789_123456789_ }{1:                             }|
          {n:一二三四五六七八九十           }{1:                             }|
          {n:abcdefghij                     }{1:                             }|
          {n:上下左右                       }{1:                             }|
          {1:~                                                           }|*2
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ]])
      end
      feed('<Esc>')

      command('set pummaxwidth=10')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_^                              |
          {1:~                                                           }|*6
        ## grid 3
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ## grid 4
          {12:123456789>}|
          {n:一二三四 >}|
          {n:abcdefghij}|
          {n:上下左右  }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_^                              |
          {12:123456789>}{1:                                                  }|
          {n:一二三四 >}{1:                                                  }|
          {n:abcdefghij}{1:                                                  }|
          {n:上下左右  }{1:                                                  }|
          {1:~                                                           }|*2
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ]])
      end
      feed('<Esc>')

      command('set rightleft')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
                                       ^ _987654321_987654321_987654321|
          {1:                                                           ~}|*6
        ## grid 3
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ## grid 4
          {12:<987654321}|
          {n:< 四三二一}|
          {n:jihgfedcba}|
          {n:  右左下上}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 50, false, 100, 1, 1, 50 } },
        })
      else
        screen:expect([[
                                       ^ _987654321_987654321_987654321|
          {1:                                                  }{12:<987654321}|
          {1:                                                  }{n:< 四三二一}|
          {1:                                                  }{n:jihgfedcba}|
          {1:                                                  }{n:  右左下上}|
          {1:                                                           ~}|*2
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ]])
      end
      feed('<Esc>')
      command('set norightleft')

      command('set pummaxwidth=2')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:------------------------------------------------------------]|*7
          [3:------------------------------------------------------------]|
        ## grid 2
          123456789_123456789_123456789_^                              |
          {1:~                                                           }|*6
        ## grid 3
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ## grid 4
          {12:1>}|
          {n: >}|
          {n:a>}|
          {n: >}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          123456789_123456789_123456789_^                              |
          {12:1>}{1:                                                          }|
          {n: >}{1:                                                          }|
          {n:a>}{1:                                                          }|
          {n: >}{1:                                                          }|
          {1:~                                                           }|*2
          {5:-- Omni completion (^O^N^P) }{6:match 1 of 4}                    |
        ]])
      end
      feed('<Esc>')

      screen:try_resize(32, 20)
      command('set pummaxwidth=14')
      command('let g:change=1')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo fooKind f>}|
          {n:bar barKind b>}|
          {n:baz bazKind b>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo fooKind f>}{1:                  }|
          {n:bar barKind b>}{1:                  }|
          {n:baz bazKind b>}{1:                  }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      -- Unicode Character U+2026 but one cell
      command('set fcs+=trunc:…')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo fooKind f…}|
          {n:bar barKind b…}|
          {n:baz bazKind b…}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo fooKind f…}{1:                  }|
          {n:bar barKind b…}{1:                  }|
          {n:baz bazKind b…}{1:                  }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('let g:change=2')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo        fo…}|
          {n:bar        一…}|
          {n:一二三四五 mu…}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo        fo…}{1:                  }|
          {n:bar        一…}{1:                  }|
          {n:一二三四五 mu…}{1:                  }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set fcs&')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo        fo>}|
          {n:bar        一>}|
          {n:一二三四五 mu>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo        fo>}{1:                  }|
          {n:bar        一>}{1:                  }|
          {n:一二三四五 mu>}{1:                  }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set fcs=trunc:_')
      command('let g:change=1')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo fooKind f_}|
          {n:bar barKind b_}|
          {n:baz bazKind b_}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo fooKind f_}{1:                  }|
          {n:bar barKind b_}{1:                  }|
          {n:baz bazKind b_}{1:                  }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')
      command('set fcs&')

      command('set rightleft')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ oof|
          {1:                               ~}|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:<f dniKoof oof}|
          {n:<b dniKrab rab}|
          {n:<b dniKzab zab}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 18, false, 100, 1, 1, 18 } },
        })
      else
        screen:expect([[
                                      ^ oof|
          {1:                  }{12:<f dniKoof oof}|
          {1:                  }{n:<b dniKrab rab}|
          {1:                  }{n:<b dniKzab zab}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('let g:change=2')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ oof|
          {1:                               ~}|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:<of        oof}|
          {n:<一        rab}|
          {n:<um 五四三二一}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 18, false, 100, 1, 1, 18 } },
        })
      else
        screen:expect([[
                                      ^ oof|
          {1:                  }{12:<of        oof}|
          {1:                  }{n:<一        rab}|
          {1:                  }{n:<um 五四三二一}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set fcs+=truncrl:…')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ oof|
          {1:                               ~}|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:…of        oof}|
          {n:…一        rab}|
          {n:…um 五四三二一}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 18, false, 100, 1, 1, 18 } },
        })
      else
        screen:expect([[
                                      ^ oof|
          {1:                  }{12:…of        oof}|
          {1:                  }{n:…一        rab}|
          {1:                  }{n:…um 五四三二一}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set fcs&')
      command('let g:change=3')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ rab|
          {1:                               ~}|*18
        ## grid 3
          {5:-- The only match}               |
        ## grid 4
          {12:<of 三二一 rab}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 18, false, 100, 1, 1, 18 } },
        })
      else
        screen:expect([[
                                      ^ rab|
          {1:                  }{12:<of 三二一 rab}|
          {1:                               ~}|*17
          {5:-- The only match}               |
        ]])
      end
      feed('<Esc>')
      command('set norightleft')

      command('set pummaxwidth=4')
      command('let g:change=2')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo>}|
          {n:bar>}|
          {n:一 >}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo>}{1:                            }|
          {n:bar>}{1:                            }|
          {n:一 >}{1:                            }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set rightleft')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ oof|
          {1:                               ~}|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:<oof}|
          {n:<rab}|
          {n:< 一}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 28, false, 100, 1, 1, 28 } },
        })
      else
        screen:expect([[
                                      ^ oof|
          {1:                            }{12:<oof}|
          {1:                            }{n:<rab}|
          {1:                            }{n:< 一}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')
      command('set norightleft')

      command('set pummaxwidth=16')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          foo^                             |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:foo        fooK>}|
          {n:bar        一二>}|
          {n:一二三四五 multi}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          foo^                             |
          {12:foo        fooK>}{1:                }|
          {n:bar        一二>}{1:                }|
          {n:一二三四五 multi}{1:                }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')

      command('set rightleft')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
                                      ^ oof|
          {1:                               ~}|*18
        ## grid 3
          {5:-- }{6:match 1 of 3}                 |
        ## grid 4
          {12:<Koof        oof}|
          {n:<二一        rab}|
          {n:itlum 五四三二一}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 16, false, 100, 1, 1, 16 } },
        })
      else
        screen:expect([[
                                      ^ oof|
          {1:                }{12:<Koof        oof}|
          {1:                }{n:<二一        rab}|
          {1:                }{n:itlum 五四三二一}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
      end
      feed('<Esc>')
      command('set norightleft')

      command('let g:change=4')
      feed('S<C-X><C-O>')
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*19
          [3:--------------------------------]|
        ## grid 2
          一二三四五六七八九十^            |
          {1:~                               }|*18
        ## grid 3
          {5:-- }{6:match 1 of 2}                 |
        ## grid 4
          {ds:一二三四五六七 }{12:>}|
          {dn:123456789_12345}{n:>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
          一二三四五六七八九十^            |
          {ds:一二三四五六七 }{12:>}{1:                }|
          {dn:123456789_12345}{n:>}{1:                }|
          {1:~                               }|*16
          {5:-- }{6:match 1 of 2}                 |
        ]])
      end
      feed('<Esc>')
    end)

    -- oldtest: Test_pum_position_when_wrap()
    it('with cursor on a wrapped line', function()
      exec([[
        func Omni_test(findstart, base)
          if a:findstart
            return col(".")
          endif
          return ['foo', 'bar', 'foobar']
        endfunc
        set omnifunc=Omni_test
        set wrap
        set cot+=noinsert
      ]])
      screen:try_resize(25, 15)

      insert(('abcde '):rep(20))

      feed('5|')
      feed('a<C-X><C-O>')
      if multigrid then
        screen:expect({
          float_pos = { [4] = { -1, 'NW', 2, 3, 4, false, 100, 1, 3, 4 } },
        })
      else
        screen:expect([[
          abcde^ abcde abcde abcde a|
          bcde abcde abcde abcde ab|
          cde abcde abcde abcde abc|
          de a{12: foo            } abcd|
          e ab{n: bar            }     |
          {1:~   }{n: foobar         }{1:     }|
          {1:~                        }|*8
          {5:-- }{6:match 1 of 3}          |
        ]])
      end
      feed('<Esc>')

      feed('30|')
      feed('a<C-X><C-O>')
      if multigrid then
        screen:expect({
          float_pos = { [4] = { -1, 'NW', 2, 4, 4, false, 100, 1, 4, 4 } },
        })
      else
        screen:expect([[
          abcde abcde abcde abcde a|
          bcde ^abcde abcde abcde ab|
          cde abcde abcde abcde abc|
          de abcde abcde abcde abcd|
          e ab{12: foo            }     |
          {1:~   }{n: bar            }{1:     }|
          {1:~   }{n: foobar         }{1:     }|
          {1:~                        }|*7
          {5:-- }{6:match 1 of 3}          |
        ]])
      end
      feed('<Esc>')

      feed('55|')
      feed('a<C-X><C-O>')
      if multigrid then
        screen:expect({
          float_pos = { [4] = { -1, 'NW', 2, 5, 4, false, 100, 1, 5, 4 } },
        })
      else
        screen:expect([[
          abcde abcde abcde abcde a|
          bcde abcde abcde abcde ab|
          cde a^bcde abcde abcde abc|
          de abcde abcde abcde abcd|
          e abcde abcde abcde      |
          {1:~   }{12: foo            }{1:     }|
          {1:~   }{n: bar            }{1:     }|
          {1:~   }{n: foobar         }{1:     }|
          {1:~                        }|*6
          {5:-- }{6:match 1 of 3}          |
        ]])
      end
      feed('<Esc>')

      feed('85|')
      feed('a<C-X><C-O>')
      if multigrid then
        screen:expect({
          float_pos = { [4] = { -1, 'NW', 2, 5, 9, false, 100, 1, 5, 9 } },
        })
      else
        screen:expect([[
          abcde abcde abcde abcde a|
          bcde abcde abcde abcde ab|
          cde abcde abcde abcde abc|
          de abcde a^bcde abcde abcd|
          e abcde abcde abcde      |
          {1:~        }{12: foo            }|
          {1:~        }{n: bar            }|
          {1:~        }{n: foobar         }|
          {1:~                        }|*6
          {5:-- }{6:match 1 of 3}          |
        ]])
      end
      feed('<C-E><Esc>')

      feed('108|')
      feed('a<C-X><C-O>')
      if multigrid then
        screen:expect({
          float_pos = { [4] = { -1, 'NW', 2, 5, 7, false, 100, 1, 5, 7 } },
        })
      else
        screen:expect([[
          abcde abcde abcde abcde a|
          bcde abcde abcde abcde ab|
          cde abcde abcde abcde abc|
          de abcde abcde abcde abcd|
          e abcde ^abcde abcde      |
          {1:~      }{12: foo            }{1:  }|
          {1:~      }{n: bar            }{1:  }|
          {1:~      }{n: foobar         }{1:  }|
          {1:~                        }|*6
          {5:-- }{6:match 1 of 3}          |
        ]])
      end
      feed('<C-E><Esc>')
    end)

    it('does not crash when displayed in last column with rightleft #12032', function()
      local col = 30
      local items = { 'word', 'choice', 'text', 'thing' }
      local max_len = 0
      for _, v in ipairs(items) do
        max_len = max_len < #v and #v or max_len
      end
      screen:try_resize(col, 8)
      command('set rightleft')
      command('call setline(1, repeat(" ", &columns - ' .. max_len .. '))')
      feed('$i')
      fn.complete(col - max_len, items)
      feed('<c-y>')
      assert_alive()
    end)

    it('truncates double-width character correctly without scrollbar', function()
      screen:try_resize(32, 8)
      command('set completeopt+=menuone,noselect')
      feed('i' .. string.rep(' ', 13))

      fn.complete(14, { '一二三四五六七八九十' })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                       ^                   |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: 一二三四五六七八九>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 12, false, 100, 1, 1, 12 } },
        })
      else
        screen:expect([[
                       ^                   |
          {1:~           }{n: 一二三四五六七八九>}|
          {1:~                               }|*5
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      fn.complete(14, { { word = '一二三', kind = '四五六', menu = '七八九十' } })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                       ^                   |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: 一二三 四五六 七八>}|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 12, false, 100, 1, 1, 12 } },
        })
      else
        screen:expect([[
                       ^                   |
          {1:~           }{n: 一二三 四五六 七八>}|
          {1:~                               }|*5
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      command('set rightleft')
      fn.complete(14, { '一二三四五六七八九十' })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                            ^              |
          {1:                               ~}|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n:<九八七六五四三二一 }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
                            ^              |
          {n:<九八七六五四三二一 }{1:           ~}|
          {1:                               ~}|*5
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      fn.complete(14, { { word = '一二三', kind = '四五六', menu = '七八九十' } })
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                            ^              |
          {1:                               ~}|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n:<八七 六五四 三二一 }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
                            ^              |
          {n:<八七 六五四 三二一 }{1:           ~}|
          {1:                               ~}|*5
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')
    end)

    it('truncates double-width character correctly with scrollbar', function()
      screen:try_resize(32, 8)
      command('set completeopt+=noselect')
      command('set pumheight=4')
      feed('i' .. string.rep(' ', 12))
      local items1 = {}
      local items2 = {}
      for _ = 1, 8 do
        table.insert(items1, { word = '一二三四五六七八九十', equal = 1, dup = 1 })
      end
      for _ = 1, 2 do
        table.insert(
          items2,
          { word = 'abcdef', kind = 'ghijkl', menu = 'mnopqrst', equal = 1, dup = 1 }
        )
      end
      for _ = 3, 8 do
        table.insert(
          items2,
          { word = '一二三', kind = '四五六', menu = '七八九十', equal = 1, dup = 1 }
        )
      end

      fn.complete(13, items1)
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                      ^                    |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: 一二三四五六七八九>}{c: }|*2
          {n: 一二三四五六七八九>}{12: }|*2
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 11, false, 100, 1, 1, 11 } },
        })
      else
        screen:expect([[
                      ^                    |
          {1:~          }{n: 一二三四五六七八九>}{c: }|*2
          {1:~          }{n: 一二三四五六七八九>}{12: }|*2
          {1:~                               }|*2
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      fn.complete(13, items2)
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                      ^                    |
          {1:~                               }|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {n: abcdef ghijkl mnopq}{c: }|*2
          {n: 一二三 四五六 七八>}{12: }|*2
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 11, false, 100, 1, 1, 11 } },
        })
      else
        screen:expect([[
                      ^                    |
          {1:~          }{n: abcdef ghijkl mnopq}{c: }|*2
          {1:~          }{n: 一二三 四五六 七八>}{12: }|*2
          {1:~                               }|*2
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      command('set rightleft')
      fn.complete(13, items1)
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                             ^             |
          {1:                               ~}|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {c: }{n:<九八七六五四三二一 }|*2
          {12: }{n:<九八七六五四三二一 }|*2
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
                             ^             |
          {c: }{n:<九八七六五四三二一 }{1:          ~}|*2
          {12: }{n:<九八七六五四三二一 }{1:          ~}|*2
          {1:                               ~}|*2
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')

      fn.complete(13, items2)
      if multigrid then
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*7
          [3:--------------------------------]|
        ## grid 2
                             ^             |
          {1:                               ~}|*6
        ## grid 3
          {5:-- INSERT --}                    |
        ## grid 4
          {c: }{n:qponm lkjihg fedcba }|*2
          {12: }{n:<八七 六五四 三二一 }|*2
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 100, 1, 1, 0 } },
        })
      else
        screen:expect([[
                             ^             |
          {c: }{n:qponm lkjihg fedcba }{1:          ~}|*2
          {12: }{n:<八七 六五四 三二一 }{1:          ~}|*2
          {1:                               ~}|*2
          {5:-- INSERT --}                    |
        ]])
      end
      feed('<C-E>')
    end)

    it('supports mousemodel=popup', function()
      screen:try_resize(32, 6)
      exec([[
        call setline(1, 'popup menu test')
        set mouse=a mousemodel=popup

        " Delete the default MenuPopup event handler.
        autocmd! nvim.popupmenu
        aunmenu PopUp
        menu PopUp.foo :let g:menustr = 'foo'<CR>
        menu PopUp.bar :let g:menustr = 'bar'<CR>
        menu PopUp.baz :let g:menustr = 'baz'<CR>
      ]])

      --- @param state string|test.function.ui.screen.Expect
      --- @param str string
      --- @param repl string
      --- @return string|test.function.ui.screen.Expect
      local function screen_replace(state, str, repl)
        if type(state) == 'string' then
          local new_state = state:gsub(vim.pesc(str), vim.pesc(repl))
          return new_state
        end
        local new_state = vim.deepcopy(state)
        local grid = assert(new_state.grid)
        grid = grid:gsub(vim.pesc(str), vim.pesc(repl))
        new_state.grid = grid
        return new_state
      end

      local no_sel_screen ---@type string|test.function.ui.screen.Expect
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 4)
        no_sel_screen = {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
                                          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 3, false, 250, 2, 1, 3 } },
        }
      else
        feed('<RightMouse><4,0>')
        no_sel_screen = [[
          ^popup menu test                 |
          {1:~  }{n: foo }{1:                        }|
          {1:~  }{n: bar }{1:                        }|
          {1:~  }{n: baz }{1:                        }|
          {1:~                               }|
                                          |
        ]]
      end
      screen:expect(no_sel_screen)
      feed('<Down>')
      screen:expect(screen_replace(no_sel_screen, '{n: foo }', '{12: foo }'))
      feed('<Down>')
      screen:expect(screen_replace(no_sel_screen, '{n: bar }', '{12: bar }'))
      feed('<CR>')
      local no_menu_screen ---@type string
      if multigrid then
        no_menu_screen = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
          :let g:menustr = 'bar'          |
        ]]
      else
        no_menu_screen = [[
          ^popup menu test                 |
          {1:~                               }|*4
          :let g:menustr = 'bar'          |
        ]]
      end
      screen:expect(no_menu_screen)
      eq('bar', api.nvim_get_var('menustr'))

      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 2, 20)
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
          :let g:menustr = 'bar'          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 19, false, 250, 2, 3, 19 } },
        })
      else
        feed('<RightMouse><20,2>')
        screen:expect([[
          ^popup menu test                 |
          {1:~                               }|*2
          {1:~                  }{n: foo }{1:        }|
          {1:~                  }{n: bar }{1:        }|
          :let g:menustr = 'b{n: baz }        |
        ]])
      end
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 18)
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
          :let g:menustr = 'bar'          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 17, false, 250, 2, 1, 17 } },
        })
      else
        feed('<RightMouse><18,0>')
        screen:expect([[
          ^popup menu test                 |
          {1:~                }{n: foo }{1:          }|
          {1:~                }{n: bar }{1:          }|
          {1:~                }{n: baz }{1:          }|
          {1:~                               }|
          :let g:menustr = 'bar'          |
        ]])
      end
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 4, 1, 3)
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
          :let g:menustr = 'bar'          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 3, 19, false, 250, 2, 3, 19 } },
        })
      else
        feed('<RightMouse><20,2>')
        screen:expect([[
          ^popup menu test                 |
          {1:~                               }|*2
          {1:~                  }{n: foo }{1:        }|
          {1:~                  }{n: bar }{1:        }|
          :let g:menustr = 'b{n: baz }        |
        ]])
      end
      if multigrid then
        api.nvim_input_mouse('left', 'press', '', 4, 2, 2)
      else
        feed('<LeftMouse><21,5>')
      end
      no_menu_screen = no_menu_screen:gsub([['bar']], [['baz']])
      screen:expect(no_menu_screen)
      eq('baz', api.nvim_get_var('menustr'))

      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 4)
        no_sel_screen = {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*5
          [3:--------------------------------]|
        ## grid 2
          ^popup menu test                 |
          {1:~                               }|*4
        ## grid 3
          :let g:menustr = 'baz'          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 3, false, 250, 2, 1, 3 } },
        }
      else
        feed('<RightMouse><4,0>')
        no_sel_screen = [[
          ^popup menu test                 |
          {1:~  }{n: foo }{1:                        }|
          {1:~  }{n: bar }{1:                        }|
          {1:~  }{n: baz }{1:                        }|
          {1:~                               }|
          :let g:menustr = 'baz'          |
        ]]
      end
      screen:expect(no_sel_screen)
      if multigrid then
        api.nvim_input_mouse('right', 'drag', '', 2, 3, 6)
      else
        feed('<RightDrag><6,3>')
      end
      screen:expect(screen_replace(no_sel_screen, '{n: baz }', '{12: baz }'))
      if multigrid then
        api.nvim_input_mouse('right', 'release', '', 2, 1, 6)
      else
        feed('<RightRelease><6,1>')
      end
      no_menu_screen = no_menu_screen:gsub([['baz']], [['foo']])
      screen:expect(no_menu_screen)
      eq('foo', api.nvim_get_var('menustr'))
      no_sel_screen = screen_replace(no_sel_screen, [['baz']], [['foo']])

      eq(false, screen.options.mousemoveevent)
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 4)
      else
        feed('<RightMouse><4,0>')
      end
      screen:expect(no_sel_screen)
      eq(true, screen.options.mousemoveevent)
      if multigrid then
        api.nvim_input_mouse('wheel', 'up', '', 2, 0, 4)
      else
        feed('<ScrollWheelUp><4,0>')
      end
      screen:expect(screen_replace(no_sel_screen, '{n: foo }', '{12: foo }'))
      eq(true, screen.options.mousemoveevent)
      if multigrid then
        api.nvim_input_mouse('move', '', '', 4, 2, 3)
      else
        feed('<MouseMove><6,3>')
      end
      screen:expect(screen_replace(no_sel_screen, '{n: baz }', '{12: baz }'))
      eq(true, screen.options.mousemoveevent)
      if multigrid then
        api.nvim_input_mouse('wheel', 'down', '', 4, 2, 3)
      else
        feed('<ScrollWheelDown><6,3>')
      end
      screen:expect(screen_replace(no_sel_screen, '{n: bar }', '{12: bar }'))
      eq(true, screen.options.mousemoveevent)
      if multigrid then
        api.nvim_input_mouse('left', 'press', '', 4, 1, 3)
      else
        feed('<LeftMouse><6,2>')
      end
      no_menu_screen = no_menu_screen:gsub([['foo']], [['bar']])
      screen:expect(no_menu_screen)
      eq(false, screen.options.mousemoveevent)
      eq('bar', api.nvim_get_var('menustr'))

      command('set laststatus=0 | botright split')
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 5, 1, 20)
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:--------------------------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'bar'          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ## grid 5
          ^popup menu test                 |
          {1:~                               }|
        ]],
          float_pos = { [4] = { -1, 'SW', 5, 1, 19, false, 250, 2, 1, 19 } },
        })
      else
        feed('<RightMouse><20,4>')
        screen:expect([[
          popup menu test                 |
          {1:~                  }{n: foo }{1:        }|
          {2:[No Name] [+]      }{n: bar }{2:        }|
          ^popup menu test    {n: baz }        |
          {1:~                               }|
          :let g:menustr = 'bar'          |
        ]])
      end
      if multigrid then
        api.nvim_input_mouse('left', 'press', '', 4, 2, 2)
        screen:expect([[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:--------------------------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'baz'          |
        ## grid 5
          ^popup menu test                 |
          {1:~                               }|
        ]])
      else
        feed('<LeftMouse><21,3>')
        screen:expect([[
          popup menu test                 |
          {1:~                               }|
          {2:[No Name] [+]                   }|
          ^popup menu test                 |
          {1:~                               }|
          :let g:menustr = 'baz'          |
        ]])
      end
      eq('baz', api.nvim_get_var('menustr'))

      command('set winwidth=1 | rightbelow vsplit')
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 6, 1, 14)
        screen:expect({
          grid = [[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:---------------]│[6:----------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'baz'          |
        ## grid 4
          {n: foo}|
          {n: bar}|
          {n: baz}|
        ## grid 5
          popup menu test|
          {1:~              }|
        ## grid 6
          ^popup menu test |
          {1:~               }|
        ]],
          float_pos = { [4] = { -1, 'SW', 6, 1, 12, false, 250, 2, 1, 28 } },
        })
      else
        feed('<RightMouse><30,4>')
        screen:expect([[
          popup menu test                 |
          {1:~                           }{n: foo}|
          {2:[No Name] [+]               }{n: bar}|
          popup menu test│^popup menu t{n: baz}|
          {1:~              }│{1:~               }|
          :let g:menustr = 'baz'          |
        ]])
      end
      if multigrid then
        api.nvim_input_mouse('left', 'press', '', 4, 0, 2)
        screen:expect([[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:---------------]│[6:----------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'foo'          |
        ## grid 5
          popup menu test|
          {1:~              }|
        ## grid 6
          ^popup menu test |
          {1:~               }|
        ]])
      else
        feed('<LeftMouse><31,1>')
        screen:expect([[
          popup menu test                 |
          {1:~                               }|
          {2:[No Name] [+]                   }|
          popup menu test│^popup menu test |
          {1:~              }│{1:~               }|
          :let g:menustr = 'foo'          |
        ]])
      end
      eq('foo', api.nvim_get_var('menustr'))

      command('setlocal winbar=WINBAR')
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 6, 1, 14)
        no_sel_screen = {
          grid = [[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:---------------]│[6:----------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'foo'          |
        ## grid 4
          {n: foo}|
          {n: bar}|
          {n: baz}|
        ## grid 5
          popup menu test|
          {1:~              }|
        ## grid 6
          {5:WINBAR          }|
          ^popup menu test |
        ]],
          float_pos = { [4] = { -1, 'SW', 6, 1, 12, false, 250, 2, 1, 28 } },
        }
      else
        feed('<RightMouse><30,4>')
        no_sel_screen = [[
          popup menu test                 |
          {1:~                           }{n: foo}|
          {2:[No Name] [+]               }{n: bar}|
          popup menu test│{5:WINBAR      }{n: baz}|
          {1:~              }│^popup menu test |
          :let g:menustr = 'foo'          |
        ]]
      end
      screen:expect(no_sel_screen)
      if multigrid then
        api.nvim_input_mouse('right', 'drag', '', 6, 0, 15)
      else
        feed('<RightDrag><31,3>')
      end
      screen:expect(screen_replace(no_sel_screen, '{n: baz}', '{12: baz}'))
      if multigrid then
        api.nvim_input_mouse('right', 'release', '', 6, 1, 15)
      else
        feed('<RightRelease><31,4>')
      end
      screen:expect(no_sel_screen)
      if multigrid then
        api.nvim_input_mouse('left', 'press', '', 4, 1, 2)
        screen:expect([[
        ## grid 1
          [2:--------------------------------]|*2
          {2:[No Name] [+]                   }|
          [5:---------------]│[6:----------------]|*2
          [3:--------------------------------]|
        ## grid 2
          popup menu test                 |
          {1:~                               }|
        ## grid 3
          :let g:menustr = 'bar'          |
        ## grid 5
          popup menu test|
          {1:~              }|
        ## grid 6
          {5:WINBAR          }|
          ^popup menu test |
        ]])
      else
        feed('<LeftMouse><31,2>')
        screen:expect([[
          popup menu test                 |
          {1:~                               }|
          {2:[No Name] [+]                   }|
          popup menu test│{5:WINBAR          }|
          {1:~              }│^popup menu test |
          :let g:menustr = 'bar'          |
        ]])
      end
      eq('bar', api.nvim_get_var('menustr'))

      command([[let g:menustr = '']])
      screen:try_resize(32, 9)
      command('wincmd t | 4vsplit | wincmd l | topleft 1split')
      if multigrid then
        no_menu_screen = [[
        ## grid 1
          [8:--------------------------------]|
          {3:[No Name] [+]                   }|
          [7:----]│[2:---------------------------]|*2
          {2:<+]  [No Name] [+]              }|
          [5:---------------]│[6:----------------]|*3
          [3:--------------------------------]|
        ## grid 2
          popup menu test            |
          {1:~                          }|
        ## grid 3
                                          |
        ## grid 5
          popup menu test|
          {1:~              }|*2
        ## grid 6
          {5:WINBAR          }|
          popup menu test |
          {1:~               }|
        ## grid 7
          popu|
          p me|
        ## grid 8
          ^popup menu test                 |
        ]]
      else
        no_menu_screen = [[
          ^popup menu test                 |
          {3:[No Name] [+]                   }|
          popu│popup menu test            |
          p me│{1:~                          }|
          {2:<+]  [No Name] [+]              }|
          popup menu test│{5:WINBAR          }|
          {1:~              }│popup menu test |
          {1:~              }│{1:~               }|
                                          |
        ]]
      end
      screen:expect(no_menu_screen)

      if multigrid then
        no_sel_screen = {
          grid = [[
        ## grid 1
          [8:--------------------------------]|
          {3:[No Name] [+]                   }|
          [7:----]│[2:---------------------------]|*2
          {2:<+]  [No Name] [+]              }|
          [5:---------------]│[6:----------------]|*3
          [3:--------------------------------]|
        ## grid 2
          popup menu test            |
          {1:~                          }|
        ## grid 3
                                          |
        ## grid 4
          {n: foo }|
          {n: bar }|
          {n: baz }|
        ## grid 5
          popup menu test|
          {1:~              }|*2
        ## grid 6
          {5:WINBAR          }|
          popup menu test |
          {1:~               }|
        ## grid 7
          popu|
          p me|
        ## grid 8
          ^popup menu test                 |
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 14, false, 250, 2, 3, 19 } },
        }
      else
        no_sel_screen = [[
          ^popup menu test                 |
          {3:[No Name] [+]                   }|
          popu│popup menu test            |
          p me│{1:~             }{n: foo }{1:        }|
          {2:<+]  [No Name] [+] }{n: bar }{2:        }|
          popup menu test│{5:WIN}{n: baz }{5:        }|
          {1:~              }│popup menu test |
          {1:~              }│{1:~               }|
                                          |
        ]]
      end

      local pos = {
        { 0, 2, 20 },
        { 0, 3, 19 },
        { 0, 3, 18 },
        { 0, 4, 23 },
        { 0, 4, 24 },
        { 0, 5, 19 },
        { 0, 5, 18 },
      }
      if multigrid then
        for i = 1, 7 do
          local _, row, col = unpack(pos[i])
          pos[i] = { 2, row - 2, col - 5 }
        end
      end

      api.nvim_input_mouse('right', 'press', '', unpack(pos[1]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[2]))
      screen:expect(screen_replace(no_sel_screen, '{n: foo }', '{12: foo }'))
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[3]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[4]))
      screen:expect(screen_replace(no_sel_screen, '{n: bar }', '{12: bar }'))
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[5]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[6]))
      screen:expect(screen_replace(no_sel_screen, '{n: baz }', '{12: baz }'))
      api.nvim_input_mouse('right', 'release', '', unpack(pos[7]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('left', 'press', '', unpack(pos[7]))
      screen:expect(no_menu_screen)
      eq('', api.nvim_get_var('menustr'))

      if multigrid then
        for i = 2, 6, 2 do
          local _, row, col = unpack(pos[i])
          pos[i] = { 4, row - 1, col - 14 }
        end
      end

      api.nvim_input_mouse('right', 'press', '', unpack(pos[1]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[2]))
      screen:expect(screen_replace(no_sel_screen, '{n: foo }', '{12: foo }'))
      api.nvim_input_mouse('move', '', '', unpack(pos[3]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[4]))
      screen:expect(screen_replace(no_sel_screen, '{n: bar }', '{12: bar }'))
      api.nvim_input_mouse('move', '', '', unpack(pos[5]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[6]))
      screen:expect(screen_replace(no_sel_screen, '{n: baz }', '{12: baz }'))
      api.nvim_input_mouse('left', 'press', '', unpack(pos[7]))
      screen:expect(no_menu_screen)
      eq('', api.nvim_get_var('menustr'))

      command('set rightleft | wincmd p | set rightleft | wincmd p')
      if multigrid then
        no_menu_screen = [[
        ## grid 1
          [8:--------------------------------]|
          {3:[No Name] [+]                   }|
          [7:----]│[2:---------------------------]|*2
          {2:<+]  [No Name] [+]              }|
          [5:---------------]│[6:----------------]|*3
          [3:--------------------------------]|
        ## grid 2
                      tset unem pupop|
          {1:                          ~}|
        ## grid 3
                                          |
        ## grid 5
          popup menu test|
          {1:~              }|*2
        ## grid 6
          {5:WINBAR          }|
          popup menu test |
          {1:~               }|
        ## grid 7
          popu|
          p me|
        ## grid 8
                           tset unem pupo^p|
        ]]
      else
        no_menu_screen = [[
                           tset unem pupo^p|
          {3:[No Name] [+]                   }|
          popu│            tset unem pupop|
          p me│{1:                          ~}|
          {2:<+]  [No Name] [+]              }|
          popup menu test│{5:WINBAR          }|
          {1:~              }│popup menu test |
          {1:~              }│{1:~               }|
                                          |
        ]]
      end
      screen:expect(no_menu_screen)

      if multigrid then
        no_sel_screen = {
          grid = [[
        ## grid 1
          [8:--------------------------------]|
          {3:[No Name] [+]                   }|
          [7:----]│[2:---------------------------]|*2
          {2:<+]  [No Name] [+]              }|
          [5:---------------]│[6:----------------]|*3
          [3:--------------------------------]|
        ## grid 2
                      tset unem pupop|
          {1:                          ~}|
        ## grid 3
                                          |
        ## grid 4
          {n: oof }|
          {n: rab }|
          {n: zab }|
        ## grid 5
          popup menu test|
          {1:~              }|*2
        ## grid 6
          {5:WINBAR          }|
          popup menu test |
          {1:~               }|
        ## grid 7
          popu|
          p me|
        ## grid 8
                           tset unem pupo^p|
        ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 12, false, 250, 2, 3, 17 } },
        }
      else
        no_sel_screen = [[
                           tset unem pupo^p|
          {3:[No Name] [+]                   }|
          popu│            tset unem pupop|
          p me│{1:            }{n: oof }{1:         ~}|
          {2:<+]  [No Name] [+}{n: rab }{2:          }|
          popup menu test│{5:W}{n: zab }{5:          }|
          {1:~              }│popup menu test |
          {1:~              }│{1:~               }|
                                          |
        ]]
      end

      pos = {
        { 0, 2, 20 },
        { 0, 3, 21 },
        { 0, 3, 22 },
        { 0, 4, 17 },
        { 0, 4, 16 },
        { 0, 5, 21 },
        { 0, 5, 22 },
      }
      if multigrid then
        for i = 1, 7 do
          local _, row, col = unpack(pos[i])
          pos[i] = { 2, row - 2, col - 5 }
        end
      end

      api.nvim_input_mouse('right', 'press', '', unpack(pos[1]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[2]))
      screen:expect(screen_replace(no_sel_screen, '{n: oof }', '{12: oof }'))
      api.nvim_input_mouse('move', '', '', unpack(pos[3]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[4]))
      screen:expect(screen_replace(no_sel_screen, '{n: rab }', '{12: rab }'))
      api.nvim_input_mouse('move', '', '', unpack(pos[5]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('move', '', '', unpack(pos[6]))
      screen:expect(screen_replace(no_sel_screen, '{n: zab }', '{12: zab }'))
      api.nvim_input_mouse('left', 'press', '', unpack(pos[7]))
      screen:expect(no_menu_screen)
      eq('', api.nvim_get_var('menustr'))

      if multigrid then
        for i = 2, 6, 2 do
          local _, row, col = unpack(pos[i])
          pos[i] = { 4, row - 1, col - 12 }
        end
      end

      api.nvim_input_mouse('right', 'press', '', unpack(pos[1]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[2]))
      screen:expect(screen_replace(no_sel_screen, '{n: oof }', '{12: oof }'))
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[3]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[4]))
      screen:expect(screen_replace(no_sel_screen, '{n: rab }', '{12: rab }'))
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[5]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('right', 'drag', '', unpack(pos[6]))
      screen:expect(screen_replace(no_sel_screen, '{n: zab }', '{12: zab }'))
      api.nvim_input_mouse('right', 'release', '', unpack(pos[7]))
      screen:expect(no_sel_screen)
      api.nvim_input_mouse('left', 'press', '', unpack(pos[7]))
      eq('', api.nvim_get_var('menustr'))

      command('set norightleft')
    end)

    if not multigrid then
      -- oldtest: Test_popup_command_dump()
      it(':popup command', function()
        exec([[
          " Delete the default MenuPopup event handler.
          autocmd! nvim.popupmenu

          func ChangeMenu()
            aunmenu PopUp.&Paste
            nnoremenu 1.40 PopUp.&Paste :echomsg "pasted"<CR>
            echomsg 'changed'
            return "\<Ignore>"
          endfunc

          let lines =<< trim END
            one two three four five
            and one two Xthree four five
            one more two three four five
          END
          call setline(1, lines)

          aunmenu *
          source $VIMRUNTIME/menu.vim
        ]])
        feed('/X<CR>:popup PopUp<CR>')
        screen:expect([[
          one two three four five         |
          and one two {10:^X}three four five    |
          one more tw{n: Undo             }   |
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Paste            }{1:   }|
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Select Word      }{1:   }|
          {1:~          }{n: Select Sentence  }{1:   }|
          {1:~          }{n: Select Paragraph }{1:   }|
          {1:~          }{n: Select Line      }{1:   }|
          {1:~          }{n: Select Block     }{1:   }|
          {1:~          }{n: Select All       }{1:   }|
          {1:~                               }|*7
          :popup PopUp                    |
        ]])

        -- go to the Paste entry in the menu
        feed('jj')
        screen:expect([[
          one two three four five         |
          and one two {10:^X}three four five    |
          one more tw{n: Undo             }   |
          {1:~          }{n:                  }{1:   }|
          {1:~          }{12: Paste            }{1:   }|
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Select Word      }{1:   }|
          {1:~          }{n: Select Sentence  }{1:   }|
          {1:~          }{n: Select Paragraph }{1:   }|
          {1:~          }{n: Select Line      }{1:   }|
          {1:~          }{n: Select Block     }{1:   }|
          {1:~          }{n: Select All       }{1:   }|
          {1:~                               }|*7
          :popup PopUp                    |
        ]])

        -- Select a word
        feed('j')
        screen:expect([[
          one two three four five         |
          and one two {10:^X}three four five    |
          one more tw{n: Undo             }   |
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Paste            }{1:   }|
          {1:~          }{n:                  }{1:   }|
          {1:~          }{12: Select Word      }{1:   }|
          {1:~          }{n: Select Sentence  }{1:   }|
          {1:~          }{n: Select Paragraph }{1:   }|
          {1:~          }{n: Select Line      }{1:   }|
          {1:~          }{n: Select Block     }{1:   }|
          {1:~          }{n: Select All       }{1:   }|
          {1:~                               }|*7
          :popup PopUp                    |
        ]])

        feed('<Esc>')

        command('set rightleft')
        feed('/X<CR>:popup PopUp<CR>')
        screen:expect([[
                   evif ruof eerht owt eno|
              evif ruof eerht{10:^X} owt eno dna|
             {n:             odnU }wt erom eno|
          {1:   }{n:                  }{1:          ~}|
          {1:   }{n:            etsaP }{1:          ~}|
          {1:   }{n:                  }{1:          ~}|
          {1:   }{n:      droW tceleS }{1:          ~}|
          {1:   }{n:  ecnetneS tceleS }{1:          ~}|
          {1:   }{n: hpargaraP tceleS }{1:          ~}|
          {1:   }{n:      eniL tceleS }{1:          ~}|
          {1:   }{n:     kcolB tceleS }{1:          ~}|
          {1:   }{n:       llA tceleS }{1:          ~}|
          {1:                               ~}|*7
          :popup PopUp                    |
        ]])
        feed('<Esc>')
        command('set norightleft')

        -- Set an <expr> mapping to change a menu entry while it's displayed.
        -- The text should not change but the command does.
        -- Also verify that "changed" shows up, which means the mapping triggered.
        command('nnoremap <expr> <F2> ChangeMenu()')
        feed('/X<CR>:popup PopUp<CR><F2>')
        screen:expect([[
          one two three four five         |
          and one two {10:^X}three four five    |
          one more tw{n: Undo             }   |
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Paste            }{1:   }|
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Select Word      }{1:   }|
          {1:~          }{n: Select Sentence  }{1:   }|
          {1:~          }{n: Select Paragraph }{1:   }|
          {1:~          }{n: Select Line      }{1:   }|
          {1:~          }{n: Select Block     }{1:   }|
          {1:~          }{n: Select All       }{1:   }|
          {1:~                               }|*7
          changed                         |
        ]])

        -- Select the Paste entry, executes the changed menu item.
        feed('jj<CR>')
        screen:expect([[
          one two three four five         |
          and one two {10:^X}three four five    |
          one more two three four five    |
          {1:~                               }|*16
          pasted                          |
        ]])

        -- Add a window toolbar to the window and check the :popup menu position.
        command('setlocal winbar=TEST')
        feed('/X<CR>:popup PopUp<CR>')
        screen:expect([[
          {5:TEST                            }|
          one two three four five         |
          and one two {10:^X}three four five    |
          one more tw{n: Undo             }   |
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Paste            }{1:   }|
          {1:~          }{n:                  }{1:   }|
          {1:~          }{n: Select Word      }{1:   }|
          {1:~          }{n: Select Sentence  }{1:   }|
          {1:~          }{n: Select Paragraph }{1:   }|
          {1:~          }{n: Select Line      }{1:   }|
          {1:~          }{n: Select Block     }{1:   }|
          {1:~          }{n: Select All       }{1:   }|
          {1:~                               }|*6
          :popup PopUp                    |
        ]])

        feed('<Esc>')
      end)
    end

    -- oldtest: Test_mouse_popup_position()
    it('position of right-click menu when clicking near edge', function()
      screen:try_resize(50, 20)
      exec([[
        set mousemodel=popup_setpos
        " Delete the default MenuPopup event handler.
        autocmd! nvim.popupmenu
        aunmenu *
        source $VIMRUNTIME/menu.vim
        call setline(1, join(range(20)))
      ]])

      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 45 - 1)
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------------------------]|*19
            [3:--------------------------------------------------]|
          ## grid 2
            0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 ^18 19 |
            {1:~                                                 }|*18
          ## grid 3
                                                              |
          ## grid 4
            {n: Undo            }|
            {n:                 }|
            {n: Paste           }|
            {n:                 }|
            {n: Select Word     }|
            {n: Select Sentence }|
            {n: Select Paragraph}|
            {n: Select Line     }|
            {n: Select Block    }|
            {n: Select All      }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 33, false, 250, 2, 1, 33 } },
        })
      else
        api.nvim_input_mouse('right', 'press', '', 0, 0, 45 - 1)
        screen:expect([[
          0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 ^18 19 |
          {1:~                                }{n: Undo            }|
          {1:~                                }{n:                 }|
          {1:~                                }{n: Paste           }|
          {1:~                                }{n:                 }|
          {1:~                                }{n: Select Word     }|
          {1:~                                }{n: Select Sentence }|
          {1:~                                }{n: Select Paragraph}|
          {1:~                                }{n: Select Line     }|
          {1:~                                }{n: Select Block    }|
          {1:~                                }{n: Select All      }|
          {1:~                                                 }|*8
                                                            |
        ]])
      end
      feed('<Esc>')

      command('set rightleft')
      if multigrid then
        api.nvim_input_mouse('right', 'press', '', 2, 0, 50 - 45)
        screen:expect({
          grid = [[
          ## grid 1
            [2:--------------------------------------------------]|*19
            [3:--------------------------------------------------]|
          ## grid 2
             91 8^1 71 61 51 41 31 21 11 01 9 8 7 6 5 4 3 2 1 0|
            {1:                                                 ~}|*18
          ## grid 3
                                                              |
          ## grid 4
            {n:            odnU }|
            {n:                 }|
            {n:           etsaP }|
            {n:                 }|
            {n:     droW tceleS }|
            {n: ecnetneS tceleS }|
            {n:hpargaraP tceleS }|
            {n:     eniL tceleS }|
            {n:    kcolB tceleS }|
            {n:      llA tceleS }|
          ]],
          float_pos = { [4] = { -1, 'NW', 2, 1, 0, false, 250, 2, 1, 0 } },
        })
      else
        api.nvim_input_mouse('right', 'press', '', 0, 0, 50 - 45)
        screen:expect([[
           91 8^1 71 61 51 41 31 21 11 01 9 8 7 6 5 4 3 2 1 0|
          {n:            odnU }{1:                                ~}|
          {n:                 }{1:                                ~}|
          {n:           etsaP }{1:                                ~}|
          {n:                 }{1:                                ~}|
          {n:     droW tceleS }{1:                                ~}|
          {n: ecnetneS tceleS }{1:                                ~}|
          {n:hpargaraP tceleS }{1:                                ~}|
          {n:     eniL tceleS }{1:                                ~}|
          {n:    kcolB tceleS }{1:                                ~}|
          {n:      llA tceleS }{1:                                ~}|
          {1:                                                 ~}|*8
                                                            |
        ]])
      end
      feed('<Esc>')
      command('set norightleft')
    end)

    if not multigrid then
      describe('"kind" and "menu"', function()
        before_each(function()
          screen:try_resize(30, 8)
          exec([[
            func CompleteFunc( findstart, base )
              if a:findstart
                return 0
              endif
              return {
                    \ 'words': [
                    \ { 'word': 'aword1', 'menu': 'extra text 1', 'kind': 'W', },
                    \ { 'word': 'aword2', 'menu': 'extra text 2', 'kind': 'W', },
                    \ { 'word': 'aword3', 'menu': 'extra text 3', 'kind': 'W', },
                    \]}
            endfunc
            set completeopt=menu
            set completefunc=CompleteFunc
          ]])
        end)

        -- oldtest: Test_pum_highlights_default()
        it('default highlight groups', function()
          feed('iaw<C-X><C-u>')
          screen:expect([[
            aword1^                        |
            {12:aword1 W extra text 1 }{1:        }|
            {n:aword2 W extra text 2 }{1:        }|
            {n:aword3 W extra text 3 }{1:        }|
            {1:~                             }|*3
            {5:-- }{6:match 1 of 3}               |
          ]])
        end)

        -- oldtest: Test_pum_highlights_custom()
        it('custom highlight groups', function()
          exec([[
            hi PmenuKind      guifg=Red guibg=Plum1
            hi PmenuKindSel   guifg=Red guibg=Grey
            hi PmenuExtra     guifg=White guibg=Plum1
            hi PmenuExtraSel  guifg=Black guibg=Grey
          ]])
          feed('iaw<C-X><C-u>')
          screen:expect([[
            aword1^                        |
            {12:aword1 }{ks:W }{xs:extra text 1 }{1:        }|
            {n:aword2 }{kn:W }{xn:extra text 2 }{1:        }|
            {n:aword3 }{kn:W }{xn:extra text 3 }{1:        }|
            {1:~                             }|*3
            {5:-- }{6:match 1 of 3}               |
          ]])
        end)
      end)

      -- oldtest: Test_pum_highlights_match()
      it('can highlight matched text', function()
        exec([[
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'foo', 'kind': 'fookind' },
                  \ { 'word': 'foofoo', 'kind': 'fookind' },
                  \ { 'word': 'foobar', 'kind': 'fookind' },
                  \ { 'word': 'fooBaz', 'kind': 'fookind' },
                  \ { 'word': 'foobala', 'kind': 'fookind' },
                  \ { 'word': '你好' },
                  \ { 'word': '你好吗' },
                  \ { 'word': '你不好吗' },
                  \ { 'word': '你可好吗' },
                  \]}
          endfunc

          func Comp()
            let col = col('.')
            if getline('.') == 'f'
              let col -= 1
            endif
            call complete(col, [
                  \ #{word: "foo", icase: 1},
                  \ #{word: "Foobar", icase: 1},
                  \ #{word: "fooBaz", icase: 1},
                  \])
            return ''
          endfunc

          set omnifunc=Omni_test
          set completeopt=menu,noinsert,fuzzy
          hi PmenuMatchSel  guifg=Blue guibg=Grey
          hi PmenuMatch     guifg=Blue guibg=Plum1
        ]])
        feed('i<C-X><C-O>')
        local pum_start = [[
          ^                                |
          {12:foo      fookind }{1:               }|
          {n:foofoo   fookind }{1:               }|
          {n:foobar   fookind }{1:               }|
          {n:fooBaz   fookind }{1:               }|
          {n:foobala  fookind }{1:               }|
          {n:你好             }{1:               }|
          {n:你好吗           }{1:               }|
          {n:你不好吗         }{1:               }|
          {n:你可好吗         }{1:               }|
          {1:~                               }|*9
          {5:-- }{6:match 1 of 9}                 |
        ]]
        screen:expect(pum_start)
        feed('fo')
        screen:expect([[
          fo^                              |
          {ms:fo}{12:o     fookind }{1:                }|
          {mn:fo}{n:ofoo  fookind }{1:                }|
          {mn:fo}{n:obar  fookind }{1:                }|
          {mn:fo}{n:oBaz  fookind }{1:                }|
          {mn:fo}{n:obala fookind }{1:                }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<Esc>S<C-X><C-O>')
        screen:expect(pum_start)
        feed('你')
        screen:expect([[
          你^                              |
          {ms:你}{12:好           }{1:                 }|
          {mn:你}{n:好吗         }{1:                 }|
          {mn:你}{n:不好吗       }{1:                 }|
          {mn:你}{n:可好吗       }{1:                 }|
          {1:~                               }|*14
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('吗')
        screen:expect([[
          你吗^                            |
          {ms:你}{12:好}{ms:吗}{12:         }{1:                 }|
          {mn:你}{n:不好}{mn:吗}{n:       }{1:                 }|
          {mn:你}{n:可好}{mn:吗}{n:       }{1:                 }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<C-E><Esc>')

        command('set rightleft')
        feed('S<C-X><C-O>')
        local pum_start_rl = [[
                                         ^ |
          {1:               }{12: dnikoof      oof}|
          {1:               }{n: dnikoof   oofoof}|
          {1:               }{n: dnikoof   raboof}|
          {1:               }{n: dnikoof   zaBoof}|
          {1:               }{n: dnikoof  alaboof}|
          {1:               }{n:             好你}|
          {1:               }{n:           吗好你}|
          {1:               }{n:         吗好不你}|
          {1:               }{n:         吗好可你}|
          {1:                               ~}|*9
          {5:-- }{6:match 1 of 9}                 |
        ]]
        screen:expect(pum_start_rl)
        feed('fo')
        screen:expect([[
                                       ^ of|
          {1:                }{12: dnikoof     o}{ms:of}|
          {1:                }{n: dnikoof  oofo}{mn:of}|
          {1:                }{n: dnikoof  rabo}{mn:of}|
          {1:                }{n: dnikoof  zaBo}{mn:of}|
          {1:                }{n: dnikoof alabo}{mn:of}|
          {1:                               ~}|*13
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<Esc>S<C-X><C-O>')
        screen:expect(pum_start_rl)
        feed('你')
        screen:expect([[
                                       ^ 你|
          {1:                 }{12:           好}{ms:你}|
          {1:                 }{n:         吗好}{mn:你}|
          {1:                 }{n:       吗好不}{mn:你}|
          {1:                 }{n:       吗好可}{mn:你}|
          {1:                               ~}|*14
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('吗')
        screen:expect([[
                                     ^ 吗你|
          {1:                 }{12:         }{ms:吗}{12:好}{ms:你}|
          {1:                 }{n:       }{mn:吗}{n:好不}{mn:你}|
          {1:                 }{n:       }{mn:吗}{n:好可}{mn:你}|
          {1:                               ~}|*15
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<C-E><Esc>')
        command('set norightleft')

        command('set completeopt-=fuzzy')
        feed('S<C-X><C-O>')
        screen:expect(pum_start)
        feed('fo')
        screen:expect([[
          fo^                              |
          {ms:fo}{12:o     fookind }{1:                }|
          {mn:fo}{n:ofoo  fookind }{1:                }|
          {mn:fo}{n:obar  fookind }{1:                }|
          {mn:fo}{n:oBaz  fookind }{1:                }|
          {mn:fo}{n:obala fookind }{1:                }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<C-E><Esc>')

        command('set rightleft')
        feed('S<C-X><C-O>')
        screen:expect(pum_start_rl)
        feed('fo')
        screen:expect([[
                                       ^ of|
          {1:                }{12: dnikoof     o}{ms:of}|
          {1:                }{n: dnikoof  oofo}{mn:of}|
          {1:                }{n: dnikoof  rabo}{mn:of}|
          {1:                }{n: dnikoof  zaBo}{mn:of}|
          {1:                }{n: dnikoof alabo}{mn:of}|
          {1:                               ~}|*13
          {5:-- }{6:match 1 of 9}                 |
        ]])
        feed('<C-E><Esc>')
        command('set norightleft')

        feed('S<C-R>=Comp()<CR>f')
        screen:expect([[
          f^                               |
          {ms:f}{12:oo            }{1:                 }|
          {mn:F}{n:oobar         }{1:                 }|
          {mn:f}{n:ooBaz         }{1:                 }|
          {1:~                               }|*15
          {5:-- INSERT --}                    |
        ]])
        feed('o<BS><C-R>=Comp()<CR>')
        screen:expect_unchanged(true)
        feed('<C-E><Esc>')

        command('hi PmenuMatchSel guibg=NONE')
        command('hi PmenuMatch guibg=NONE')
        command('set cot=menu,noinsert,fuzzy')
        feed('S<C-X><C-O>')
        screen:expect(pum_start)
        feed('fb')
        screen:expect([[
          fb^                              |
          {ms:f}{12:oo}{ms:B}{12:az  fookind }{1:                }|
          {mn:f}{n:oo}{mn:b}{n:ar  fookind }{1:                }|
          {mn:f}{n:oo}{mn:b}{n:ala fookind }{1:                }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 9}                 |
        ]])

        feed('<C-E><Esc>')
      end)

      it('completefuzzycollect', function()
        exec([[
          set completefuzzycollect=keyword,files
          set completeopt=menu,menuone
        ]])

        feed('S hello helio hero h<C-X><C-P>')
        screen:expect([[
           hello helio hero hello^         |
          {1:~                }{n: hero         }{1: }|
          {1:~                }{n: helio        }{1: }|
          {1:~                }{12: hello        }{1: }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])

        feed('<Esc>S hello helio hero h<C-X><C-P><C-P>')
        screen:expect([[
           hello helio hero helio^         |
          {1:~                }{n: hero         }{1: }|
          {1:~                }{12: helio        }{1: }|
          {1:~                }{n: hello        }{1: }|
          {1:~                               }|*15
          {5:-- }{6:match 2 of 3}                 |
        ]])

        feed('<Esc>S/non_existing_folder<C-X><C-F>')
        screen:expect([[
          /non_existing_folder^            |
          {1:~                               }|*18
          {5:-- }{9:Pattern not found}            |
        ]])
        feed('<C-E><Esc>')
      end)

      -- oldtest: Test_pum_highlights_match_with_abbr()
      it('can highlight matched text with abbr', function()
        exec([[
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'foobar', 'abbr': "foobar\t\t!" },
                  \ { 'word': 'foobaz', 'abbr': "foobaz\t\t!" },
                  \]}
          endfunc

          set omnifunc=Omni_test
          set completeopt=menuone,noinsert
          hi PmenuMatchSel  guifg=Blue guibg=Grey
          hi PmenuMatch     guifg=Blue guibg=Plum1
        ]])
        feed('i<C-X><C-O>')
        screen:expect([[
          ^                                |
          {12:foobar    !    }{1:                 }|
          {n:foobaz    !    }{1:                 }|
          {1:~                               }|*16
          {5:-- }{6:match 1 of 2}                 |
        ]])
        feed('foo')
        screen:expect([[
          foo^                             |
          {ms:foo}{12:bar    !    }{1:                 }|
          {mn:foo}{n:baz    !    }{1:                 }|
          {1:~                               }|*16
          {5:-- }{6:match 1 of 2}                 |
        ]])

        feed('<C-E><Esc>')
      end)

      -- oldtest: Test_pum_user_abbr_hlgroup()
      it('custom abbr_hlgroup override', function()
        exec([[
          let s:var = 0
          func CompleteFunc(findstart, base)
            if a:findstart
              return 0
            endif
            if s:var == 1
              return {
                    \ 'words': [
                    \ { 'word': 'aword1', 'abbr_hlgroup': 'StrikeFake' },
                    \ { 'word': '你好', 'abbr_hlgroup': 'StrikeFake' },
                    \]}
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'aword1', 'menu': 'extra text 1', 'kind': 'W', 'abbr_hlgroup': 'StrikeFake' },
                  \ { 'word': 'aword2', 'menu': 'extra text 2', 'kind': 'W', },
                  \ { 'word': '你好', 'menu': 'extra text 3', 'kind': 'W', 'abbr_hlgroup': 'StrikeFake' },
                  \]}
          endfunc
          func ChangeVar()
            let s:var = 1
          endfunc
          set completeopt=menu
          set completefunc=CompleteFunc

          hi StrikeFake guifg=DarkRed
          func HlMatch()
            hi PmenuMatchSel  guifg=Blue guibg=Grey gui=underline
            hi PmenuMatch     guifg=Blue guibg=Plum1 gui=underline
          endfunc
        ]])

        feed('Saw<C-X><C-U>')
        screen:expect([[
          aword1^                          |
          {ds:aword1}{12: W extra text 1 }{1:          }|
          {n:aword2 W extra text 2 }{1:          }|
          {dn:你好}{n:   W extra text 3 }{1:          }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        command('call HlMatch()')

        feed('Saw<C-X><C-U>')
        screen:expect([[
          aword1^                          |
          {uds:aw}{ds:ord1}{12: W extra text 1 }{1:          }|
          {umn:aw}{n:ord2 W extra text 2 }{1:          }|
          {dn:你好}{n:   W extra text 3 }{1:          }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-N>')
        screen:expect([[
          aword2^                          |
          {udn:aw}{dn:ord1}{n: W extra text 1 }{1:          }|
          {ums:aw}{12:ord2 W extra text 2 }{1:          }|
          {dn:你好}{n:   W extra text 3 }{1:          }|
          {1:~                               }|*15
          {5:-- }{6:match 2 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        command('call ChangeVar()')
        feed('S<C-X><C-U>')
        screen:expect([[
          aword1^                          |
          {ds:aword1}{12:         }{1:                 }|
          {dn:你好}{n:           }{1:                 }|
          {1:~                               }|*16
          {5:-- }{6:match 1 of 2}                 |
        ]])
        feed('<C-E><Esc>')
      end)

      -- oldtest: Test_pum_user_kind_hlgroup()
      it('custom kind_hlgroup override', function()
        exec([[
          func CompleteFunc( findstart, base )
            if a:findstart
              return 0
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'aword1', 'menu': 'extra text 1', 'kind': 'variable', 'kind_hlgroup': 'KindVar', 'abbr_hlgroup': 'StrikeFake' },
                  \ { 'word': 'aword2', 'menu': 'extra text 2', 'kind': 'function', 'kind_hlgroup': 'KindFunc' },
                  \ { 'word': '你好', 'menu': 'extra text 3', 'kind': 'class', 'kind_hlgroup': 'KindClass'  },
                  \]}
          endfunc
          set completeopt=menu
          set completefunc=CompleteFunc

          hi StrikeFake guifg=DarkRed
          hi KindVar guifg=DarkYellow
          hi KindFunc guifg=DarkBlue
          hi KindClass guifg=DarkGreen
        ]])

        feed('S<C-X><C-U>')
        screen:expect([[
          aword1^                          |
          {ds:aword1}{12: }{110:variable}{12: extra text 1 }{1:   }|
          {n:aword2 }{111:function}{n: extra text 2 }{1:   }|
          {n:你好   }{112:class}{n:    extra text 3 }{1:   }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><Esc>')
      end)

      -- oldtest: Test_pum_completeitemalign()
      it('completeitemalign option', function()
        screen:try_resize(30, 15)
        exec([[
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'foo', 'kind': 'S', 'menu': 'menu' },
                  \ { 'word': 'bar', 'kind': 'T', 'menu': 'menu' },
                  \ { 'word': '你好', 'kind': 'C', 'menu': '中文' },
                  \]}
          endfunc

          func Omni_long(findstart, base)
            if a:findstart
              return col(".")
            endif
            return {
                  \ 'words': [
                  \ { 'word': 'loooong_foo', 'kind': 'S', 'menu': 'menu' },
                  \ { 'word': 'loooong_bar', 'kind': 'T', 'menu': 'menu' },
                  \]}
          endfunc
          set omnifunc=Omni_test
        ]])
        -- T1
        command('set cia=abbr,kind,menu')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:foo  S menu    }{1:               }|
          {n:bar  T menu    }{1:               }|
          {n:你好 C 中文    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T2
        command('set cia=abbr,menu,kind')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:foo  menu S    }{1:               }|
          {n:bar  menu T    }{1:               }|
          {n:你好 中文 C    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T3
        command('set cia=kind,abbr,menu')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:S foo  menu    }{1:               }|
          {n:T bar  menu    }{1:               }|
          {n:C 你好 中文    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T4
        command('set cia=kind,menu,abbr')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:S menu foo     }{1:               }|
          {n:T menu bar     }{1:               }|
          {n:C 中文 你好    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T5
        command('set cia=menu,abbr,kind')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:menu foo  S    }{1:               }|
          {n:menu bar  T    }{1:               }|
          {n:中文 你好 C    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T6
        command('set cia=menu,kind,abbr')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:menu S foo     }{1:               }|
          {n:menu T bar     }{1:               }|
          {n:中文 C 你好    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')
        -- T7
        command('set cia&')
        feed('S<C-X><C-O>')
        screen:expect([[
          foo^                           |
          {12:foo  S menu    }{1:               }|
          {n:bar  T menu    }{1:               }|
          {n:你好 C 中文    }{1:               }|
          {1:~                             }|*10
          {5:-- }{6:match 1 of 3}               |
        ]])
        feed('<C-E><ESC>')

        -- Test_pum_completeitemalign_07
        command('set cia=menu,kind,abbr columns=12 cmdheight=2 omnifunc=Omni_long')
        feed('S<C-X><C-O>')
        screen:expect([[
          loooong_foo^ |
          {12:menu S loooo}|
          {n:menu T loooo}|
          {1:~           }|*10
                      |
          {5:--}          |
        ]])
        feed('<C-E><ESC>')
      end)

      -- oldtest: Test_pum_matchins_highlight()
      it('with ComplMatchIns highlight', function()
        exec([[
          let g:change = 0
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            if g:change == 0
              return [#{word: "foo"}, #{word: "bar"}, #{word: "你好"}]
            endif
            return [#{word: "foo", info: "info"}, #{word: "bar"}, #{word: "你好"}]
          endfunc
          set completeopt-=popup completeopt+=preview
          set omnifunc=Omni_test
          hi ComplMatchIns guifg=red
        ]])

        feed('Sαβγ <C-X><C-O>')
        screen:expect([[
          αβγ {19:foo}^                         |
          {1:~  }{12: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        feed('Sαβγ <C-X><C-O><C-N>')
        screen:expect([[
          αβγ {19:bar}^                         |
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{12: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 2 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        feed('Sαβγ <C-X><C-O><C-N><C-N>')
        screen:expect([[
          αβγ {19:你好}^                        |
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{12: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 3 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        -- restore after accept
        feed('Sαβγ <C-X><C-O><C-Y>')
        screen:expect([[
          αβγ foo^                         |
          {1:~                               }|*18
          {5:-- INSERT --}                    |
        ]])
        feed('<Esc>')

        -- restore after cancel completion
        feed('Sαβγ <C-X><C-O><Space>')
        screen:expect([[
          αβγ foo ^                        |
          {1:~                               }|*18
          {5:-- INSERT --}                    |
        ]])
        feed('<Esc>')

        -- text after the inserted text shouldn't be highlighted
        feed('0ea <C-X><C-O>')
        screen:expect([[
          αβγ {19:foo}^ foo                     |
          {1:~  }{12: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-P>')
        screen:expect([[
          αβγ ^ foo                        |
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{19:Back at original}             |
        ]])
        feed('<C-P>')
        screen:expect([[
          αβγ {19:你好}^ foo                    |
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{12: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 3 of 3}                 |
        ]])
        feed('<C-Y>')
        screen:expect([[
          αβγ 你好^ foo                    |
          {1:~                               }|*18
          {5:-- INSERT --}                    |
        ]])
        feed('<Esc>')

        feed(':let g:change=1<CR>S<C-X><C-O>')
        screen:expect([[
          info                            |
          {1:~                               }|*2
          {2:[Scratch] [Preview][-]          }|
          {19:foo}^                             |
          {12:foo            }{1:                 }|
          {n:bar            }{1:                 }|
          {n:你好           }{1:                 }|
          {1:~                               }|*10
          {3:[No Name] [+]                   }|
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<Esc>')
      end)

      -- oldtest: Test_pum_matchins_highlight_combine()
      it('with ComplMatchIns, Normal and CursorLine highlights', function()
        exec([[
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            return [#{word: "foo"}, #{word: "bar"}, #{word: "你好"}]
          endfunc
          set completeopt-=popup completeopt+=preview
          " Avoid unwanted results in case local workspace has a "tags" file.
          set complete-=t
          set omnifunc=Omni_test
          hi Normal guibg=blue
          hi CursorLine guibg=green guifg=white
          set cursorline
          call setline(1, 'aaa bbb')
        ]])

        -- when ComplMatchIns is not set, CursorLine applies normally
        feed('0ea <C-X><C-O>')
        screen:expect([[
          {101:aaa foo^ bbb                     }|
          {1:~  }{12: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E>')
        screen:expect([[
          {101:aaa ^ bbb                        }|
          {1:~                               }|*18
          {5:-- INSERT --}                    |
        ]])
        feed('<BS><Esc>')

        -- when ComplMatchIns is set, it is applied over CursorLine
        command('hi ComplMatchIns guifg=Yellow')
        feed('0ea <C-X><C-O>')
        screen:expect([[
          {101:aaa }{100:foo}{101:^ bbb                     }|
          {1:~  }{12: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-P>')
        screen:expect([[
          {101:aaa ^ bbb                        }|
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{n: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{19:Back at original}             |
        ]])
        feed('<C-P>')
        screen:expect([[
          {101:aaa }{100:你好}{101:^ bbb                    }|
          {1:~  }{n: foo            }{1:             }|
          {1:~  }{n: bar            }{1:             }|
          {1:~  }{12: 你好           }{1:             }|
          {1:~                               }|*15
          {5:-- }{6:match 3 of 3}                 |
        ]])
        feed('<C-E>')
        screen:expect([[
          {101:aaa ^ bbb                        }|
          {1:~                               }|*18
          {5:-- INSERT --}                    |
        ]])
        feed('<Esc>')

        -- Does not highlight the compl leader
        command('set completeopt+=menuone,noselect')
        feed('S<C-X><C-O>')
        local pum_start = [[
          {101:^                                }|
          {n:foo            }{1:                 }|
          {n:bar            }{1:                 }|
          {n:你好           }{1:                 }|
          {1:~                               }|*15
          {5:-- }{19:Back at original}             |
        ]]
        screen:expect(pum_start)
        feed('f<C-N>')
        screen:expect([[
          {101:f}{100:oo}{101:^                             }|
          {12:foo            }{1:                 }|
          {1:~                               }|*17
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><ESC>')

        command('set completeopt+=fuzzy')
        feed('S<C-X><C-O>')
        screen:expect(pum_start)
        feed('f<C-N>')
        screen:expect([[
          {101:foo^                             }|
          {12:foo            }{1:                 }|
          {1:~                               }|*17
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><Esc>')

        command('set completeopt-=fuzzy')
        feed('Sf<C-N>')
        screen:expect([[
          {101:f^                               }|
          {1:~                               }|*18
          {5:-- }{9:Pattern not found}            |
        ]])
        feed('<C-E><Esc>')
      end)

      -- oldtest: Test_pum_complete_with_special_characters()
      it('multi-line completion', function()
        exec([[
          func Omni_test(findstart, base)
            if a:findstart
              return col(".")
            endif
            return [#{word: "func ()\n\t\nend", abbr: "function ()",}, #{word: "foobar"}, #{word: "你好\n\t\n我好"}]
          endfunc
          set omnifunc=Omni_test
          inoremap <F5> <Cmd>call complete(col('.'), [ "my\n\tmulti\nline", "my\n\t\tmulti\nline" ])<CR>
        ]])

        feed('S<C-X><C-O>')
        screen:expect([[
          func ()                         |
                                          |
          end^                             |
          {12:function ()    }{1:                 }|
          {n:foobar         }{1:                 }|
          {n:你好^@  ^@我好 }{1:                 }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 3}                 |
        ]])

        feed('<C-N>')
        screen:expect([[
          foobar^                          |
          {n:function ()    }{1:                 }|
          {12:foobar         }{1:                 }|
          {n:你好^@  ^@我好 }{1:                 }|
          {1:~                               }|*15
          {5:-- }{6:match 2 of 3}                 |
        ]])
        feed('<C-E><ESC>')

        feed('Shello  hero<ESC>hhhhha<C-X><C-O>')
        screen:expect([[
          hello func ()                   |
                                          |
          end^ hero                        |
          {1:~    }{12: function ()    }{1:           }|
          {1:~    }{n: foobar         }{1:           }|
          {1:~    }{n: 你好^@  ^@我好 }{1:           }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 3}                 |
        ]])

        feed('<C-N>')
        screen:expect([[
          hello foobar^ hero               |
          {1:~    }{n: function ()    }{1:           }|
          {1:~    }{12: foobar         }{1:           }|
          {1:~    }{n: 你好^@  ^@我好 }{1:           }|
          {1:~                               }|*15
          {5:-- }{6:match 2 of 3}                 |
        ]])

        feed('<C-N>')
        screen:expect([[
          hello 你好                      |
                                          |
          我好^ hero                       |
          {1:~  }{n: function ()    }{1:             }|
          {1:~  }{n: foobar         }{1:             }|
          {1:~  }{12: 你好^@  ^@我好 }{1:             }|
          {1:~                               }|*13
          {5:-- }{6:match 3 of 3}                 |
        ]])

        feed('<C-N>')
        screen:expect([[
          hello ^ hero                     |
          {1:~    }{n: function ()    }{1:           }|
          {1:~    }{n: foobar         }{1:           }|
          {1:~    }{n: 你好^@  ^@我好 }{1:           }|
          {1:~                               }|*15
          {5:-- }{19:Back at original}             |
        ]])
        feed('<C-E><ESC>')

        command(':hi ComplMatchIns guifg=red')
        feed('S<C-X><C-O>')
        screen:expect([[
          {19:func ()}                         |
          {19:        }                        |
          {19:end}^                             |
          {12:function ()    }{1:                 }|
          {n:foobar         }{1:                 }|
          {n:你好^@  ^@我好 }{1:                 }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><ESC>')

        feed('Shello  hero<ESC>hhhhha<C-X><C-O>')
        screen:expect([[
          hello {19:func ()}                   |
          {19:        }                        |
          {19:end^ }hero                        |
          {1:~    }{12: function ()    }{1:           }|
          {1:~    }{n: foobar         }{1:           }|
          {1:~    }{n: 你好^@  ^@我好 }{1:           }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 3}                 |
        ]])
        feed('<C-E><ESC>')

        command('setlocal autoindent shiftwidth=2 tabstop=2')
        feed('Slocal a = <C-X><C-O>')
        screen:expect([[
          local a = {19:func ()}               |
          {19:  }                              |
          {19:end}^                             |
          {1:~ }{12: function ()    }{1:              }|
          {1:~ }{n: foobar         }{1:              }|
          {1:~ }{n: 你好^@  ^@我好 }{1:              }|
          {1:~                               }|*13
          {5:-- }{6:match 1 of 3}                 |
        ]])

        feed('<C-Y>')
        screen:expect([[
          local a = {19:func ()}               |
          {19:  }                              |
          end^                             |
          {1:~                               }|*16
          {5:-- INSERT --}                    |
        ]])

        feed('<ESC>kAlocal b = <C-X><C-O>')
        screen:expect([[
          local a = {19:func ()}               |
            local b = {19:func ()}             |
          {19:    }                            |
          {19:  end}^                           |
          end {12: function ()    }            |
          {1:~   }{n: foobar         }{1:            }|
          {1:~   }{n: 你好^@  ^@我好 }{1:            }|
          {1:~                               }|*12
          {5:-- }{6:match 1 of 3}                 |
        ]])

        feed('<C-Y>')
        screen:expect([[
          local a = {19:func ()}               |
            local b = {19:func ()}             |
          {19:    }                            |
            end^                           |
          end                             |
          {1:~                               }|*14
          {5:-- INSERT --}                    |
        ]])

        feed('<Esc>ggVGd')
        command('filetype indent on')
        command('setlocal noautoindent shiftwidth& tabstop&')
        command('setlocal ft=lua')
        feed('S<F5>')
        screen:expect([[
          {19:my}                              |
          {19:        multi}                   |
          {19:line}^                            |
          {12:my^@  multi^@line   }{1:            }|
          {n:my^@    multi^@line }{1:            }|
          {1:~                               }|*14
          {5:-- INSERT --}                    |
        ]])
      end)

      -- oldtest: Test_pum_clear_when_switch_tab_or_win()
      it('is cleared when switching tab or win', function()
        screen:try_resize(55, 20)
        exec([[
          inoremap <F4> <Cmd>wincmd w<CR>
          inoremap <F5> <Cmd>tabnext<CR>
        ]])

        command('tabe')
        feed('Aaa aaa <C-X><C-N>')
        screen:expect([[
          {24: [No Name] }{5: + [No Name] }{2:                              }{24:X}|
          aa aaa aa^                                              |
          {1:~     }{12: aa             }{1:                                 }|
          {1:~     }{n: aaa            }{1:                                 }|
          {1:~                                                      }|*15
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}        |
        ]])
        feed('<F5>')
        screen:expect([[
          {5: [No Name] }{24: + [No Name] }{2:                              }{24:X}|
          ^                                                       |
          {1:~                                                      }|*17
          {5:-- INSERT --}                                           |
        ]])
        feed('<Esc>')
        command('tabclose!')

        command('vnew win_b')
        feed('Abb bbb <C-X><C-N>')
        screen:expect([[
          bb bbb bb^                  │aa aaa aa                  |
          {1:~     }{12: bb             }{1:     }│{1:~                          }|
          {1:~     }{n: bbb            }{1:     }│{1:~                          }|
          {1:~                          }│{1:~                          }|*15
          {3:win_b [+]                   }{2:[No Name] [+]              }|
          {5:-- Keyword Local completion (^N^P) }{6:match 1 of 2}        |
        ]])
        feed('<F4>')
        screen:expect([[
          bb bbb bb                  │aa aaa a^a                  |
          {1:~                          }│{1:~                          }|*17
          {2:win_b [+]                   }{3:[No Name] [+]              }|
          {5:-- INSERT --}                                           |
        ]])
      end)
    end
  end

  describe('with ext_multigrid', function()
    with_ext_multigrid(true)
  end)

  describe('without ext_multigrid', function()
    with_ext_multigrid(false)
  end)
end)
