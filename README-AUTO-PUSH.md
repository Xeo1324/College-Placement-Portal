# Auto push on save

This project includes a small PowerShell watcher that will automatically stage, commit, and push changes when files in the repository are modified (for example when you press Ctrl+S in VS Code).

Files added:
- `auto-push-on-save.ps1` : PowerShell file-watcher that runs `git add -A`, `git commit`, and `git push` (debounced).
- `.vscode/tasks.json` : VS Code task to run the watcher.

Usage
1. Make sure `git` is installed and available in your PATH.
2. Ensure you can push to the remote (set up SSH key or have credentials cached for HTTPS).
3. In VS Code, open the `College Placement Portal` folder.
4. Open the Command Palette (Ctrl+Shift+P) and run `Tasks: Run Task` → `Run Auto Push Watcher`.
   - Alternatively start the task from the `Terminal` → `Run Task...` menu.
5. Keep the watcher running. When you save files, the watcher will auto-commit and push.

Notes & Safety
- Commits are auto-generated with message `Auto-save: <timestamp>`.
- The script stages everything (`git add -A`). If you want selective staging, modify the script.
- The watcher ignores changes inside `.git`, `.vscode`, `node_modules`, and a few temp file patterns.
- Be careful not to commit secrets or credentials. Review changes locally if desired.

Customization
- To change the branch or remote, edit the top of `auto-push-on-save.ps1` or pass params when running:
  `powershell -File .\auto-push-on-save.ps1 -Branch dev -Remote origin`

If you want, I can also:
- add a safer commit flow that prompts before pushing,
- set up a GitHub Actions workflow instead (for remote auto-deploy), or
- create a VS Code extension config that auto-commits only certain file types.
