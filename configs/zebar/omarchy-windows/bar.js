// The pinned client API is loaded from esm.sh. Internet is needed on first load.
const status = document.getElementById('status');
const clock = document.getElementById('clock');
function tick() { clock.textContent = new Date().toLocaleString([], { weekday: 'short', hour: '2-digit', minute: '2-digit' }); }
tick(); setInterval(tick, 1000);
try {
  const zebar = await import('https://esm.sh/zebar@3.0.0');
  const providers = zebar.createProviderGroup({ wm: { type: 'glazewm' } });
  function render() {
    const wm = providers.outputMap.wm;
    if (!wm) { status.textContent = 'Waiting for GlazeWM'; return; }
    const nav = document.getElementById('workspaces');
    nav.replaceChildren();
    for (const workspace of wm.currentWorkspaces) {
      const button = document.createElement('button');
      button.textContent = workspace.displayName || workspace.name;
      button.className = workspace.name === wm.displayedWorkspace?.name ? 'active' : '';
      button.onclick = () => wm.runCommand(`focus --workspace ${workspace.name}`).catch(error => { status.textContent = error.message; });
      nav.append(button);
    }
    status.textContent = wm.isPaused ? 'PAUSED | Alt+Shift+P to resume' : 'Win+Enter terminal | Alt+H/J/K/L focus';
  }
  providers.onOutput(render); render();
} catch (error) { status.textContent = 'Bar API unavailable. Check internet access and Zebar version.'; console.error(error); }
