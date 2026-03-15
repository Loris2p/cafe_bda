/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import React from 'react';
import type { LoadableSettingScope, LoadedSettings, LoadedSettingsSnapshot, SettingsFile } from '../../config/settings.js';
export declare const SettingsContext: React.Context<LoadedSettings | undefined>;
export declare const useSettings: () => LoadedSettings;
export interface SettingsState extends LoadedSettingsSnapshot {
    forScope: (scope: LoadableSettingScope) => SettingsFile;
}
export interface SettingsStoreValue {
    settings: SettingsState;
    setSetting: (scope: LoadableSettingScope, key: string, value: unknown) => void;
}
export declare const useSettingsStore: () => SettingsStoreValue;
