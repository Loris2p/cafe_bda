/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import React, { useContext, useMemo, useSyncExternalStore } from 'react';
import { SettingScope } from '../../config/settings.js';
export const SettingsContext = React.createContext(undefined);
export const useSettings = () => {
    const context = useContext(SettingsContext);
    if (context === undefined) {
        throw new Error('useSettings must be used within a SettingsProvider');
    }
    return context;
};
// Components that call this hook will re render when a settings change event is emitted
export const useSettingsStore = () => {
    const store = useContext(SettingsContext);
    if (store === undefined) {
        throw new Error('useSettingsStore must be used within a SettingsProvider');
    }
    // React passes a listener fn into the subscribe function
    // When the listener runs, it re renders the component if the snapshot changed
    const snapshot = useSyncExternalStore((listener) => store.subscribe(listener), () => store.getSnapshot());
    const settings = useMemo(() => ({
        ...snapshot,
        forScope: (scope) => {
            switch (scope) {
                case SettingScope.User:
                    return snapshot.user;
                case SettingScope.Workspace:
                    return snapshot.workspace;
                case SettingScope.System:
                    return snapshot.system;
                case SettingScope.SystemDefaults:
                    return snapshot.systemDefaults;
                default:
                    throw new Error(`Invalid scope: ${scope}`);
            }
        },
    }), [snapshot]);
    return useMemo(() => ({
        settings,
        setSetting: (scope, key, value) => store.setValue(scope, key, value),
    }), [settings, store]);
};
//# sourceMappingURL=SettingsContext.js.map