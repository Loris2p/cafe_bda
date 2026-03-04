/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { ArgumentsCamelCase, CommandModule } from 'yargs';
import type { MergedSettings } from './config/settings.js';
export interface DeferredCommand {
    handler: (argv: ArgumentsCamelCase) => void | Promise<void>;
    argv: ArgumentsCamelCase;
    commandName: string;
}
export declare function setDeferredCommand(command: DeferredCommand): void;
export declare function runDeferredCommand(settings: MergedSettings): Promise<void>;
/**
 * Wraps a command's handler to defer its execution.
 * It stores the handler and arguments in a singleton `deferredCommand` variable.
 */
export declare function defer<T = object, U = object>(commandModule: CommandModule<T, U>, parentCommandName?: string): CommandModule<T, U>;
