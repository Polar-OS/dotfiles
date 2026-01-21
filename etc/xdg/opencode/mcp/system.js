const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { CallToolRequestSchema, ListToolsRequestSchema } = require("@modelcontextprotocol/sdk/types.js");
const { exec } = require("child_process");
const util = require("util");
const fs = require("fs").promises;
const path = require("path");

const execPromise = util.promisify(exec);

const server = new Server(
  {
    name: "system-control",
    version: "2.9.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

async function runCommand(command) {
  try {
    const { stdout, stderr } = await execPromise(command);
    return stdout.trim();
  } catch (error) {
    throw new Error(`Command failed: ${error.message}`);
  }
}

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "notify",
        description: "Send a system notification",
        inputSchema: {
          type: "object",
          properties: {
            title: { type: "string" },
            message: { type: "string" },
          },
          required: ["message"],
        },
      },
      {
        name: "set_volume",
        description: "Set system volume percentage (0-100)",
        inputSchema: {
          type: "object",
          properties: { percentage: { type: "number" } },
          required: ["percentage"],
        },
      },
      {
        name: "get_status",
        description: "Get basic system status (Volume, Battery)",
        inputSchema: { type: "object", properties: {} },
      },
      {
        name: "set_power_profile",
        description: "Set CPU power profile.",
        inputSchema: {
          type: "object",
          properties: {
            profile: { 
              type: "string", 
              enum: ["performance", "balanced", "power-saver"]
            }
          },
          required: ["profile"],
        },
      },
      {
        name: "apply_theme",
        description: "Apply an existing color scheme by ID or query. Use this for 'switch to' or 'set' requests.",
        inputSchema: {
          type: "object",
          properties: { query: { type: "string" } },
          required: ["query"],
        },
      },
      {
        name: "generate_theme_al_vuelo",
        description: "Create and apply a BRAND NEW dynamic color scheme based on a topic. It rebuilds ALL tinty templates (Niri, Ghostty, Nvim, etc.) to ensure global application.",
        inputSchema: {
          type: "object",
          properties: {
            theme_name: { type: "string" },
            colors: {
              type: "object",
              properties: {
                base00: { type: "string" }, base01: { type: "string" }, base02: { type: "string" }, base03: { type: "string" },
                base04: { type: "string" }, base05: { type: "string" }, base06: { type: "string" }, base07: { type: "string" },
                base08: { type: "string" }, base09: { type: "string" }, base0A: { type: "string" }, base0B: { type: "string" },
                base0C: { type: "string" }, base0D: { type: "string" }, base0E: { type: "string" }, base0F: { type: "string" }
              },
              required: ["base00", "base05", "base08", "base0B", "base0D"]
            }
          },
          required: ["theme_name", "colors"],
        },
      },
      {
        name: "get_system_health",
        description: "Diagnose system performance.",
        inputSchema: { type: "object", properties: {} },
      },
      {
        name: "find_and_focus_window",
        description: "Cinematic window focus transition.",
        inputSchema: {
          type: "object",
          properties: { query: { type: "string" } },
          required: ["query"],
        },
      },
      {
        name: "reorganize_windows",
        description: "Reorganize all windows across all workspaces by category.",
        inputSchema: { type: "object", properties: {} },
      },
      {
        name: "reorganize_current_workspace",
        description: "Reorganize windows in the current workspace into a grid layout.",
        inputSchema: {
          type: "object",
          properties: { columns: { type: "number", default: 2 } },
        },
      },
      {
        name: "manage_workspace",
        description: "Create, rename, or unset the name of a workspace.",
        inputSchema: {
          type: "object",
          properties: {
            action: { type: "string", enum: ["create", "rename", "unset_name"] },
            name: { type: "string" }
          },
          required: ["action"],
        },
      },
      {
        name: "control_panel",
        description: "Control shell panels.",
        inputSchema: {
          type: "object",
          properties: { panel: { type: "string" }, action: { type: "string" } },
          required: ["panel", "action"],
        },
      },
      {
        name: "pomodoro",
        description: "Control Pomodoro.",
        inputSchema: {
          type: "object",
          properties: { action: { type: "string" } },
          required: ["action"],
        },
      },
      {
        name: "screenshot",
        description: "Take a screenshot.",
        inputSchema: {
          type: "object",
          properties: { type: { type: "string" } },
          required: ["type"],
        },
      },
      {
        name: "search_shortcuts",
        description: "Search in Cheatsheet.",
        inputSchema: {
          type: "object",
          properties: { query: { type: "string" } },
          required: ["query"],
        },
      },
      {
        name: "ipc_call",
        description: "Generic IPC call.",
        inputSchema: {
          type: "object",
          properties: {
            target: { type: "string" },
            method: { type: "string" },
            args: { type: "array", items: { type: "string" } }
          },
          required: ["target", "method"],
        },
      }
    ],
  };
});

const PANEL_MAP = {
  "wifi": "ui.panel.wifi", "bluetooth": "ui.panel.bluetooth", "audio": "ui.panel.audio",
  "battery": "ui.panel.battery", "cpu": "ui.panel.cpu", "launcher": "ui.dialog.launcher",
  "about": "ui.dialog.about", "cheatsheet": "ui.dialog.cheatsheet", "logout": "ui.dialog.logout",
  "lockscreen": "ui.overlay.lockscreen", "screensaver": "ui.overlay.screensaver",
  "voice": "ui.overlay.voice", "notifications": "ui.panel.notifications", "status": "ui.panel.status"
};

const CATEGORY_MAP = {
  "Terminal": ["ghostty", "kitty", "foot", "alacritty"],
  "Browser": ["zen", "firefox", "chromium", "chrome"],
  "Music": ["spotify"],
  "Communication": ["zapzap", "telegram", "discord"],
  "Productivity": ["ticktick", "obsidian", "code"]
};

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === "notify") {
      await runCommand(`notify-send "${(args.title || "System").replace(/"/g, '\\"')}" "${args.message.replace(/"/g, '\\"')}"`);
      return { content: [{ type: "text", text: `Sent` }] };
    }

    if (name === "set_volume") {
      await runCommand(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${args.percentage / 100}`);
      return { content: [{ type: "text", text: `Volume set` }] };
    }

    if (name === "set_power_profile") {
      await runCommand(`qs ipc call ui.power setProfile ${args.profile}`);
      return { content: [{ type: "text", text: `Power profile set` }] };
    }

    if (name === "apply_theme") {
      const listOutput = await runCommand(`tinty list | grep -i "${args.query.replace(/"/g, "")}" | head -n 1`).catch(() => "");
      if (!listOutput) throw new Error(`No theme found for "${args.query}"`);
      const themeId = listOutput.trim();
      const configUpdate = JSON.stringify({ theme: themeId, shellTheme: themeId, shellColors: false });
      await runCommand(`qs ipc call ui.config update '${configUpdate.replace(/'/g, "'\\''")}'`);
      await runCommand(`tinty apply ${themeId}`);
      return { content: [{ type: "text", text: `Switched to ${themeId}` }] };
    }

    if (name === "generate_theme_al_vuelo") {
      const slug = args.theme_name.toLowerCase().replace(/[^a-z0-9]/g, "-");
      const schemeId = `base16-${slug}`;
      const baseDir = path.join(process.env.HOME, ".local/share/tinted-theming/tinty/repos");
      const schemeDir = path.join(baseDir, "schemes/base16");
      const schemePath = path.join(schemeDir, `${slug}.yaml`);
      
      const yaml = `system: "base16"\nname: "${args.theme_name}"\nauthor: "Antigravity MCP"\nvariant: "dark"\npalette:\n` +
        Object.keys(args.colors).map(k => `  ${k}: "${args.colors[k]}"`).join("\n");

      await fs.mkdir(schemeDir, { recursive: true });
      await fs.writeFile(schemePath, yaml);
      
      const repos = ["quickshell", "niri", "ghostty", "tmux", "opencode", "vim", "gtk"];
      for (const repo of repos) {
        await runCommand(`tinty build ${path.join(baseDir, repo)}`).catch(err => console.error(`Build failed for ${repo}:`, err));
      }
      
      await runCommand(`tinty apply ${schemeId}`);

      const configUpdate = JSON.stringify({ theme: schemeId, shellTheme: schemeId, shellColors: false });
      await runCommand(`qs ipc call ui.config update '${configUpdate.replace(/'/g, "'\\''")}'`);
      
      return { content: [{ type: "text", text: `Theme "${args.theme_name}" created and applied globally (Nvim included).` }] };
    }

    if (name === "get_status") {
      const v = await runCommand("wpctl get-volume @DEFAULT_AUDIO_SINK@").catch(() => "?");
      const b = await runCommand("upower -i $(upower -e | grep 'BAT') | grep -E 'state|percentage'").catch(() => "?");
      return { content: [{ type: "text", text: `Vol: ${v}\nBatt: ${b}` }] };
    }

    if (name === "get_system_health") {
      const m = await runCommand("free -h").catch(() => "?");
      const c = await runCommand("ps -eo pcpu,comm --sort=-pcpu | head -n 4").catch(() => "?");
      return { content: [{ type: "text", text: `RAM: ${m}\nCPU:\n${c}` }] };
    }

    if (name === "find_and_focus_window") {
      const windows = JSON.parse(await runCommand("niri msg -j windows"));
      const query = args.query.toLowerCase();
      const found = windows.find(w => (w.title && w.title.toLowerCase().includes(query)) || (w.app_id && w.app_id.toLowerCase().includes(query)));
      if (!found) throw new Error("Window not found");

      const workspaces = JSON.parse(await runCommand("niri msg -j workspaces"));
      const targetWs = workspaces.find(ws => ws.id === found.workspace_id);
      
      await runCommand("niri msg action open-overview");
      await new Promise(r => setTimeout(r, 400));
      await runCommand(`niri msg action focus-workspace "${targetWs.name || targetWs.idx}"`);
      await new Promise(r => setTimeout(r, 800));
      await runCommand(`niri msg action focus-window --id ${found.id}`);
      await runCommand("niri msg action close-overview");
      await runCommand(`niri msg action center-window`);
      return { content: [{ type: "text", text: `Focused ${found.title}` }] };
    }

    if (name === "reorganize_windows") {
      const windows = JSON.parse(await runCommand("niri msg -j windows"));
      const workspaces = JSON.parse(await runCommand("niri msg -j workspaces"));
      await runCommand("niri msg action open-overview");
      await new Promise(r => setTimeout(r, 600));

      for (const window of windows) {
        let targetName = null;
        for (const [cat, ids] of Object.entries(CATEGORY_MAP)) {
           if (ids.some(id => (window.app_id && window.app_id.toLowerCase().includes(id)) || (window.title && window.title.toLowerCase().includes(id)))) {
             targetName = cat; break;
           }
        }
        if (targetName) {
          const targetWs = workspaces.find(ws => ws.name === targetName);
          const currentWs = workspaces.find(ws => ws.id === window.workspace_id);
          if (targetWs && currentWs && window.workspace_id !== targetWs.id) {
            await runCommand(`niri msg action focus-workspace "${currentWs.name || currentWs.idx}"`);
            await new Promise(r => setTimeout(r, 400));
            await runCommand(`niri msg action move-window-to-workspace "${targetName}" --window-id ${window.id}`);
            await runCommand(`niri msg action focus-workspace "${targetName}"`);
            await runCommand(`niri msg action focus-window --id ${window.id}`);
            await runCommand(`niri msg action center-window`);
            await new Promise(r => setTimeout(r, 600));
          }
        }
      }
      await runCommand("niri msg action close-overview");
      return { content: [{ type: "text", text: `Sorted` }] };
    }

    if (name === "reorganize_current_workspace") {
      const numCols = args.columns || 2;
      const workspaces = JSON.parse(await runCommand("niri msg -j workspaces"));
      const activeWs = workspaces.find(ws => ws.is_active);
      if (!activeWs) throw new Error("No active workspace");

      const windows = JSON.parse(await runCommand("niri msg -j windows"));
      const wsWindows = windows.filter(w => w.workspace_id === activeWs.id);
      if (wsWindows.length <= 1) return { content: [{ type: "text", text: "Too few windows" }] };

      await runCommand("niri msg action open-overview");
      await new Promise(r => setTimeout(r, 500));

      for (const win of wsWindows) {
        await runCommand(`niri msg action focus-window --id ${win.id}`);
        await runCommand(`niri msg action expel-window-from-column`);
        await new Promise(r => setTimeout(r, 100));
      }

      const colWindows = Array.from({ length: numCols }, () => []);
      wsWindows.forEach((win, i) => colWindows[i % numCols].push(win));

      for (let c = 0; c < numCols; c++) {
        const winsInCol = colWindows[c];
        if (winsInCol.length === 0) continue;
        const baseWin = winsInCol[0];
        await runCommand(`niri msg action focus-window --id ${baseWin.id}`);
        await runCommand(`niri msg action move-column-to-index ${c + 1}`);
        await new Promise(r => setTimeout(r, 300));
        for (let r = 1; r < winsInCol.length; r++) {
          const stackWin = winsInCol[r];
          await runCommand(`niri msg action focus-window --id ${stackWin.id}`);
          await new Promise(r => setTimeout(r, 300));
          await runCommand(`niri msg action move-column-to-index ${c + 2}`);
          await new Promise(r => setTimeout(r, 300));
          await runCommand(`niri msg action focus-window --id ${baseWin.id}`);
          await runCommand(`niri msg action consume-window-into-column`);
          await new Promise(r => setTimeout(r, 400));
        }
        
        const widthPercent = (100 / numCols).toFixed(2) + "%";
        if (winsInCol.length > 0) {
           await runCommand(`niri msg action focus-window --id ${winsInCol[0].id}`);
           await runCommand(`niri msg action set-column-width "${widthPercent}"`);
        }
      }

      for (const win of wsWindows) {
        await runCommand(`niri msg action focus-window --id ${win.id}`);
        await runCommand(`niri msg action reset-window-height`);
        await runCommand(`niri msg action center-window`);
      }

      await runCommand("niri msg action close-overview");
      return { content: [{ type: "text", text: `Grid applied` }] };
    }

    if (name === "manage_workspace") {
      if (args.action === "rename") {
        if (!args.name) throw new Error("Name is required for rename action");
        await runCommand(`niri msg action set-workspace-name "${args.name.replace(/"/g, '\\"')}"`);
        return { content: [{ type: "text", text: `Renamed current workspace to "${args.name}"` }] };
      }
      if (args.action === "unset_name") {
        await runCommand(`niri msg action unset-workspace-name`);
        return { content: [{ type: "text", text: `Unset name of current workspace` }] };
      }
      if (args.action === "create") {
        if (!args.name) throw new Error("Name is required for create action");
        const workspaces = JSON.parse(await runCommand("niri msg -j workspaces"));
        const maxIdx = workspaces.reduce((max, ws) => Math.max(max, ws.idx || 0), 0);
        const newIdx = maxIdx + 1;
        
        await runCommand(`niri msg action focus-workspace ${newIdx}`);
        await runCommand(`niri msg action set-workspace-name "${args.name.replace(/"/g, '\\"')}"`);
        
        return { content: [{ type: "text", text: `Created workspace "${args.name}" at index ${newIdx}` }] };
      }
    }

    if (name === "control_panel") {
      const target = PANEL_MAP[args.panel];
      if (!target) throw new Error("Panel not found");
      await runCommand(`qs ipc call ${target} ${args.action}`);
      return { content: [{ type: "text", text: `Done` }] };
    }

    if (name === "pomodoro") {
      await runCommand(`qs ipc call ui.timer.pomodoro ${args.action}`);
      return { content: [{ type: "text", text: `Sent` }] };
    }

    if (name === "screenshot") {
      let cmd = args.type === "window" ? "screenshot-window" : (args.type === "screen" ? "screenshot-screen" : "screenshot");
      await runCommand(`niri msg action ${cmd}`);
      return { content: [{ type: "text", text: `Taken` }] };
    }

    if (name === "search_shortcuts") {
      await runCommand(`qs ipc call ui.dialog.cheatsheet search "${args.query.replace(/"/g, '\\"')}"`);
      return { content: [{ type: "text", text: `Searching` }] };
    }

    if (name === "ipc_call") {
      await runCommand(`qs ipc call ${args.target} ${args.method} ${args.args ? args.args.join(" ") : ""}`);
      return { content: [{ type: "text", text: `Called` }] };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (error) {
    return { content: [{ type: "text", text: `Error: ${error.message}` }], isError: true };
  }
});

async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

run().catch(console.error);
