import { jsx as _jsx } from "react/jsx-runtime";
import { Component } from 'react';
import { renderHook, render } from '../../test-utils/render.js';
import { act } from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SettingsContext, useSettingsStore } from './SettingsContext.js';
import { SettingScope, createTestMergedSettings, } from '../../config/settings.js';
const createMockSettingsFile = (path) => ({
    path,
    settings: {},
    originalSettings: {},
});
const mockSnapshot = {
    system: createMockSettingsFile('/system'),
    systemDefaults: createMockSettingsFile('/defaults'),
    user: createMockSettingsFile('/user'),
    workspace: createMockSettingsFile('/workspace'),
    isTrusted: true,
    errors: [],
    merged: createTestMergedSettings({
        ui: { theme: 'default-theme' },
    }),
};
class ErrorBoundary extends Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }
    static getDerivedStateFromError(_error) {
        return { hasError: true };
    }
    componentDidCatch(error) {
        this.props.onError(error);
    }
    render() {
        if (this.state.hasError) {
            return null;
        }
        return this.props.children;
    }
}
const TestHarness = () => {
    useSettingsStore();
    return null;
};
describe('SettingsContext', () => {
    let mockLoadedSettings;
    let listeners = [];
    beforeEach(() => {
        listeners = [];
        mockLoadedSettings = {
            subscribe: vi.fn((listener) => {
                listeners.push(listener);
                return () => {
                    listeners = listeners.filter((l) => l !== listener);
                };
            }),
            getSnapshot: vi.fn(() => mockSnapshot),
            setValue: vi.fn(),
        };
    });
    const wrapper = ({ children }) => (_jsx(SettingsContext.Provider, { value: mockLoadedSettings, children: children }));
    it('should provide the correct initial state', () => {
        const { result } = renderHook(() => useSettingsStore(), { wrapper });
        expect(result.current.settings.merged).toEqual(mockSnapshot.merged);
        expect(result.current.settings.isTrusted).toBe(true);
    });
    it('should allow accessing settings for a specific scope', () => {
        const { result } = renderHook(() => useSettingsStore(), { wrapper });
        const userSettings = result.current.settings.forScope(SettingScope.User);
        expect(userSettings).toBe(mockSnapshot.user);
        const workspaceSettings = result.current.settings.forScope(SettingScope.Workspace);
        expect(workspaceSettings).toBe(mockSnapshot.workspace);
    });
    it('should trigger re-renders when settings change (external event)', () => {
        const { result } = renderHook(() => useSettingsStore(), { wrapper });
        expect(result.current.settings.merged.ui?.theme).toBe('default-theme');
        const newSnapshot = {
            ...mockSnapshot,
            merged: { ui: { theme: 'new-theme' } },
        };
        mockLoadedSettings.getSnapshot.mockReturnValue(newSnapshot);
        // Trigger the listeners (simulate coreEvents emission)
        act(() => {
            listeners.forEach((l) => l());
        });
        expect(result.current.settings.merged.ui?.theme).toBe('new-theme');
    });
    it('should call store.setValue when setSetting is called', () => {
        const { result } = renderHook(() => useSettingsStore(), { wrapper });
        act(() => {
            result.current.setSetting(SettingScope.User, 'ui.theme', 'dark');
        });
        expect(mockLoadedSettings.setValue).toHaveBeenCalledWith(SettingScope.User, 'ui.theme', 'dark');
    });
    it('should throw error if used outside provider', () => {
        const onError = vi.fn();
        // Suppress console.error (React logs error boundary info)
        const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => { });
        render(_jsx(ErrorBoundary, { onError: onError, children: _jsx(TestHarness, {}) }));
        expect(onError).toHaveBeenCalledWith(expect.objectContaining({
            message: 'useSettingsStore must be used within a SettingsProvider',
        }));
        consoleSpy.mockRestore();
    });
});
//# sourceMappingURL=SettingsContext.test.js.map