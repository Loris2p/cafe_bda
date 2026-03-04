/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { CommandKind } from './types.js';
export const shellsCommand = {
    name: 'shells',
    altNames: ['bashes'],
    kind: CommandKind.BUILT_IN,
    description: 'Toggle background shells view',
    autoExecute: true,
    action: async (context) => {
        context.ui.toggleBackgroundShell();
    },
};
//# sourceMappingURL=shellsCommand.js.map