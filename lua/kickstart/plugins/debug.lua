-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'Mgenuit/nvim-dap-kotlin',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        local file = vim.fn.expand('%:p')
        if vim.fn.fnamemodify(file, ':t'):match('%.spec%.ts$') then
          require('dap').run({
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest File",
            program = vim.fn.getcwd() .. '/node_modules/.bin/jest',
            args = { vim.fn.fnamemodify(file, ':.'), '--runInBand', '--watchAll=false' },
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
          })
          return
        end
        if vim.fn.fnamemodify(file, ':t') == 'package.json' then
          local content = vim.fn.readfile(file)
          local json_str = table.concat(content, '\n')
          local ok, json = pcall(vim.fn.json_decode, json_str)
          if ok and json and json.scripts and json.scripts.start then
            local start = json.scripts.start
            local node_cmd = start:match("&&%s*(.+)")
            if node_cmd then
              local args = {}
              for arg in node_cmd:gmatch("%S+") do
                table.insert(args, arg)
              end
              if #args > 0 and args[1] == 'node' then
                table.remove(args, 1)
                table.insert(args, 1, '--inspect')
                local program = table.remove(args)
                local abs_program = vim.fn.getcwd() .. '/' .. program
                require('dap').run({
                  type = "pwa-node",
                  request = "launch",
                  name = "Debug start script",
                  program = abs_program,
                  cwd = vim.fn.getcwd(),
                  runtimeArgs = args,
                  sourceMaps = true,
                  protocol = "inspector",
                  console = "integratedTerminal",
                })
                return
              end
            end
          end
        end
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },

    ------- YAKUAKE HACK ----
    --local map = vim.keymap.set
    --
    --map('n', '<Esc>O2Q', '<S-F2>')
    --map('n', '<Esc>O2R', '<S-F3>')
    --map('n', '<Esc>O2S', '<S-F4>')
    --map('n', '<Esc>[15;2~', '<S-F5>')
    --map('n', '<Esc>[17;2~', '<S-F6>')
    --map('n', '<Esc>[18;2~', '<S-F7>')
    --map('n', '<Esc>[19;2~', '<S-F8>')
    --map('n', '<Esc>[20;2~', '<S-F9>')
    --map('n', '<Esc>[21;2~', '<S-F10>')
    --map('n', '<Esc>[23;2~', '<S-F11>')
    --map('n', '<Esc>[24;2~', '<S-F12>')
    ------- END YAKUAKE HACK -----
    {
      '<F7>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F8>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<S-F8>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<Esc>[19;2~', -- yakuake patch
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },

    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F11>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'js-debug-adapter',
        'java-debug-adapter',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that are more likely to work in every terminal.
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    require('dap-kotlin').setup {
      dap_command = vim.fn.stdpath('data') .. '/mason/packages/kotlin-debug-adapter/adapter/bin/kotlin-debug-adapter'
    }

    dap.adapters.kotlin = {
      type = 'executable',
      command = vim.fn.stdpath('data') .. '/mason/packages/kotlin-debug-adapter/adapter/bin/kotlin-debug-adapter',
    }

    dap.configurations.kotlin = {
      {
        type = 'kotlin',
        request = 'launch',
        name = 'Debug (Launch) - Current File',
        mainClass = '${fileBasenameNoExtension}Kt',
        projectName = '${workspaceFolderBasename}',
        projectRoot = '${workspaceFolder}',
        classPaths = { '${workspaceFolder}/build/classes/kotlin/main' },
        sourcePaths = { '${workspaceFolder}/src/main/kotlin' },
      },
      {
        type = 'kotlin',
        request = 'attach',
        name = 'Debug (Attach) - Remote',
        hostName = '127.0.0.1',
        port = 5005,
      },
    }

    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      },
    }

    dap.configurations.javascript = {
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch Node",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        protocol = "inspector",
        console = "integratedTerminal",
      },
    }

    dap.configurations.typescript = dap.configurations.javascript

    -- Java Debug Adapter
    dap.adapters.java = {
      type = 'executable',
      command = 'java',
      args = {
        '-jar',
        vim.fn.stdpath("data") .. '/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-0.53.2.jar',
      },
    }


    dap.configurations.java = {
      {
        type = 'java',
        request = 'launch',
        name = 'Debug (Launch) - Current File',
        mainClass = '${file}',
        projectName = '${workspaceFolderBasename}',
      },
      {
        type = 'java',
        request = 'attach',
        name = 'Debug (Attach) - Remote',
        hostName = '127.0.0.1',
        port = 5005,
      },
    }
  end,
}
