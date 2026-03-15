/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { SettingScope, type LoadedSettings } from '../config/settings.js';
import type { ModifiedScope } from './skillSettings.js';
export type HookActionStatus = 'success' | 'no-op' | 'error';
/**
 * Metadata representing the result of a hook settings operation.
 */
export interface HookActionResult {
    status: HookActionStatus;
    hookName: string;
    action: 'enable' | 'disable';
    /** Scopes where the hook's state was actually changed. */
    modifiedScopes: ModifiedScope[];
    /** Scopes where the hook was already in the desired state. */
    alreadyInStateScopes: ModifiedScope[];
    /** Error message if status is 'error'. */
    error?: string;
}
/**
 * Enables a hook by removing it from all writable disabled lists (User and Workspace).
 */
export declare function enableHook(settings: LoadedSettings, hookName: string): HookActionResult;
/**
 * Disables a hook by adding it to the disabled list in the specified scope.
 */
export declare function disableHook(settings: LoadedSettings, hookName: string, scope: SettingScope): HookActionResult;
