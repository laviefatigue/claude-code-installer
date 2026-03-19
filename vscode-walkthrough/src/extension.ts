import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    // Register command to manually open the walkthrough
    const openWalkthrough = vscode.commands.registerCommand(
        'claude-walkthrough.openWalkthrough',
        () => {
            vscode.commands.executeCommand(
                'workbench.action.openWalkthrough',
                'laviefatigue.claude-code-walkthrough#claude-code-welcome',
                false
            );
        }
    );

    context.subscriptions.push(openWalkthrough);

    // Show walkthrough on first install
    const hasShownWalkthrough = context.globalState.get('hasShownWalkthrough');

    if (!hasShownWalkthrough) {
        // Small delay to let VS Code fully load
        setTimeout(() => {
            vscode.commands.executeCommand(
                'workbench.action.openWalkthrough',
                'laviefatigue.claude-code-walkthrough#claude-code-welcome',
                true // open to side
            );
            context.globalState.update('hasShownWalkthrough', true);
        }, 2000);
    }
}

export function deactivate() {}
