import { coreEvents, ExitCodes, getAdminErrorMessage, } from '@google/gemini-cli-core';
import { runExitCleanup } from './utils/cleanup.js';
import process from 'node:process';
let deferredCommand;
export function setDeferredCommand(command) {
    deferredCommand = command;
}
export async function runDeferredCommand(settings) {
    if (!deferredCommand) {
        return;
    }
    const adminSettings = settings.admin;
    const commandName = deferredCommand.commandName;
    if (commandName === 'mcp' && adminSettings?.mcp?.enabled === false) {
        coreEvents.emitFeedback('error', getAdminErrorMessage('MCP', undefined /* config */));
        await runExitCleanup();
        process.exit(ExitCodes.FATAL_CONFIG_ERROR);
    }
    if (commandName === 'extensions' &&
        adminSettings?.extensions?.enabled === false) {
        coreEvents.emitFeedback('error', getAdminErrorMessage('Extensions', undefined /* config */));
        await runExitCleanup();
        process.exit(ExitCodes.FATAL_CONFIG_ERROR);
    }
    if (commandName === 'skills' && adminSettings?.skills?.enabled === false) {
        coreEvents.emitFeedback('error', getAdminErrorMessage('Agent skills', undefined /* config */));
        await runExitCleanup();
        process.exit(ExitCodes.FATAL_CONFIG_ERROR);
    }
    // Inject settings into argv
    const argvWithSettings = {
        ...deferredCommand.argv,
        settings,
    };
    await deferredCommand.handler(argvWithSettings);
    await runExitCleanup();
    process.exit(ExitCodes.SUCCESS);
}
/**
 * Wraps a command's handler to defer its execution.
 * It stores the handler and arguments in a singleton `deferredCommand` variable.
 */
export function defer(commandModule, parentCommandName) {
    return {
        ...commandModule,
        handler: (argv) => {
            setDeferredCommand({
                // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
                handler: commandModule.handler,
                // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
                argv: argv,
                commandName: parentCommandName || 'unknown',
            });
        },
    };
}
//# sourceMappingURL=deferred.js.map