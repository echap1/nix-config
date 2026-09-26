# Debugger. F-keys match Zed; <Space>d… does the same for keyboards without easy F-keys.
#
# Adapters, all from nixpkgs:
#   Rust / C / C++  CodeLLDB (same adapter Zed uses)
#   Python          debugpy (uses the project's venv if VIRTUAL_ENV is set)
#   Go              delve
# Project launch configs go in .vscode/launch.json, which nvim-dap reads automatically.
{ pkgs, lib, ... }:
let
  codelldb = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";

  dap = fn: lib.nixvim.mkRaw "function() require('dap').${fn} end";
  map = key: action: desc: {
    mode = "n";
    inherit key action;
    options.desc = desc;
  };
in
{
  plugins = {
    dap = {
      enable = true;
      signs = {
        dapBreakpoint = {
          text = "●";
          texthl = "DiagnosticError";
        };
        dapBreakpointCondition = {
          text = "◆";
          texthl = "DiagnosticWarn";
        };
        dapLogPoint = {
          text = "◆";
          texthl = "DiagnosticInfo";
        };
        dapStopped = {
          text = "▶";
          texthl = "DiagnosticOk";
          linehl = "Visual";
        };
        dapBreakpointRejected = {
          text = "○";
          texthl = "DiagnosticHint";
        };
      };
    };

    dap-ui.enable = true;
    dap-virtual-text.enable = true;

    dap-lldb = {
      enable = true;
      settings.codelldb_path = codelldb;
    };
    dap-python.enable = true;
    dap-go = {
      enable = true;
      settings.delve.path = lib.getExe pkgs.delve;
    };
  };

  # Open the debugger panels when a session starts and close them when it ends
  extraConfigLua = ''
    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.after.event_initialized.dapui = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui = function() dapui.close() end
    dap.listeners.before.event_exited.dapui = function() dapui.close() end
  '';

  keymaps = [
    # Zed defaults
    (map "<F4>" (dap "continue()") "Debug: start")
    (map "<F5>" (dap "continue()") "Debug: continue")
    (map "<S-F5>" (dap "terminate()") "Debug: stop")
    (map "<F17>" (dap "terminate()") "Debug: stop") # how many terminals send Shift+F5
    (map "<C-S-F5>" (dap "restart()") "Debug: restart")
    (map "<F9>" (dap "toggle_breakpoint()") "Toggle breakpoint")
    (map "<F10>" (dap "step_over()") "Debug: step over")
    (map "<F11>" (dap "step_into()") "Debug: step into")
    (map "<S-F11>" (dap "step_out()") "Debug: step out")
    (map "<F23>" (dap "step_out()") "Debug: step out") # Shift+F11 in many terminals
    (map "<C-S-d>" (lib.nixvim.mkRaw "function() require('dapui').toggle() end") "Debug panel")

    # Leader versions
    (map "<leader>db" (dap "toggle_breakpoint()") "Toggle breakpoint")
    (map "<leader>dB"
      (lib.nixvim.mkRaw "function() require('dap').set_breakpoint(vim.fn.input('Condition: ')) end")
      "Conditional breakpoint"
    )
    (map "<leader>dc" (dap "continue()") "Start / continue")
    (map "<leader>dl" (dap "run_last()") "Run last")
    (map "<leader>dr" (dap "restart()") "Restart")
    (map "<leader>dt" (dap "terminate()") "Stop")
    (map "<leader>do" (dap "step_over()") "Step over")
    (map "<leader>di" (dap "step_into()") "Step into")
    (map "<leader>dO" (dap "step_out()") "Step out")
    (map "<leader>dC" (dap "run_to_cursor()") "Run to cursor")
    (map "<leader>du" (lib.nixvim.mkRaw "function() require('dapui').toggle() end") "Toggle debug UI")
    {
      mode = [
        "n"
        "x"
      ];
      key = "<leader>de";
      action = lib.nixvim.mkRaw "function() require('dapui').eval() end";
      options.desc = "Evaluate expression";
    }
  ];
}
