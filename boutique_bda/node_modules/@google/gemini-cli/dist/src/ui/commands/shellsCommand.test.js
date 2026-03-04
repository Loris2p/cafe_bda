/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { describe, it, expect, vi } from 'vitest';
import { shellsCommand } from './shellsCommand.js';
describe('shellsCommand', () => {
    it('should call toggleBackgroundShell', async () => {
        const toggleBackgroundShell = vi.fn();
        const context = {
            ui: {
                toggleBackgroundShell,
            },
        };
        if (shellsCommand.action) {
            await shellsCommand.action(context, '');
        }
        expect(toggleBackgroundShell).toHaveBeenCalled();
    });
    it('should have correct name and altNames', () => {
        expect(shellsCommand.name).toBe('shells');
        expect(shellsCommand.altNames).toContain('bashes');
    });
    it('should auto-execute', () => {
        expect(shellsCommand.autoExecute).toBe(true);
    });
});
//# sourceMappingURL=shellsCommand.test.js.map