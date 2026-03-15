/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { ModelSlashCommandEvent, logModelSlashCommand, } from '@google/gemini-cli-core';
import { CommandKind, } from './types.js';
import { MessageType } from '../types.js';
const setModelCommand = {
    name: 'set',
    description: 'Set the model to use. Usage: /model set <model-name> [--persist]',
    kind: CommandKind.BUILT_IN,
    autoExecute: false,
    action: async (context, args) => {
        const parts = args.trim().split(/\s+/).filter(Boolean);
        if (parts.length === 0) {
            context.ui.addItem({
                type: MessageType.ERROR,
                text: 'Usage: /model set <model-name> [--persist]',
            });
            return;
        }
        const modelName = parts[0];
        const persist = parts.includes('--persist');
        if (context.services.config) {
            context.services.config.setModel(modelName, !persist);
            const event = new ModelSlashCommandEvent(modelName);
            logModelSlashCommand(context.services.config, event);
            context.ui.addItem({
                type: MessageType.INFO,
                text: `Model set to ${modelName}${persist ? ' (persisted)' : ''}`,
            });
        }
    },
};
const manageModelCommand = {
    name: 'manage',
    description: 'Opens a dialog to configure the model',
    kind: CommandKind.BUILT_IN,
    autoExecute: true,
    action: async (context) => {
        if (context.services.config) {
            await context.services.config.refreshUserQuota();
        }
        return {
            type: 'dialog',
            dialog: 'model',
        };
    },
};
export const modelCommand = {
    name: 'model',
    description: 'Manage model configuration',
    kind: CommandKind.BUILT_IN,
    autoExecute: false,
    subCommands: [manageModelCommand, setModelCommand],
    action: async (context, args) => manageModelCommand.action(context, args),
};
//# sourceMappingURL=modelCommand.js.map