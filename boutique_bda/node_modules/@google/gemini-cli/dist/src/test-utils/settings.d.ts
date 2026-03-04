/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { LoadedSettings, type SettingsError } from '../config/settings.js';
export interface MockSettingsFile {
    settings: any;
    originalSettings: any;
    path: string;
}
interface CreateMockSettingsOptions {
    system?: MockSettingsFile;
    systemDefaults?: MockSettingsFile;
    user?: MockSettingsFile;
    workspace?: MockSettingsFile;
    isTrusted?: boolean;
    errors?: SettingsError[];
    merged?: any;
    [key: string]: any;
}
/**
 * Creates a mock LoadedSettings object for testing.
 *
 * @param overrides - Partial settings or LoadedSettings properties to override.
 *                   If 'merged' is provided, it overrides the computed merged settings.
 *                   Any functions in overrides are assigned directly to the LoadedSettings instance.
 */
export declare const createMockSettings: (overrides?: CreateMockSettingsOptions) => LoadedSettings;
export {};
