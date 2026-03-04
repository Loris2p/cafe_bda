/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { useState, useCallback } from 'react';
import { themeManager } from '../themes/theme-manager.js';
import { MessageType } from '../types.js';
import process from 'node:process';
import { useTerminalContext } from '../contexts/TerminalContext.js';
export const useThemeCommand = (loadedSettings, setThemeError, addItem, initialThemeError, refreshStatic) => {
    const [isThemeDialogOpen, setIsThemeDialogOpen] = useState(!!initialThemeError);
    const { queryTerminalBackground } = useTerminalContext();
    const openThemeDialog = useCallback(async () => {
        if (process.env['NO_COLOR']) {
            addItem({
                type: MessageType.INFO,
                text: 'Theme configuration unavailable due to NO_COLOR env variable.',
            }, Date.now());
            return;
        }
        // Ensure we have an up to date terminal background color when opening the
        // theme dialog as the user may have just changed it before opening the
        // dialog.
        await queryTerminalBackground();
        setIsThemeDialogOpen(true);
    }, [addItem, queryTerminalBackground]);
    const applyTheme = useCallback((themeName) => {
        if (!themeManager.setActiveTheme(themeName)) {
            // If theme is not found, open the theme selection dialog and set error message
            setIsThemeDialogOpen(true);
            setThemeError(`Theme "${themeName}" not found.`);
        }
        else {
            setThemeError(null); // Clear any previous theme error on success
        }
    }, [setThemeError]);
    const handleThemeHighlight = useCallback((themeName) => {
        applyTheme(themeName);
    }, [applyTheme]);
    const closeThemeDialog = useCallback(() => {
        // Re-apply the saved theme to revert any preview changes from highlighting
        applyTheme(loadedSettings.merged.ui.theme);
        setIsThemeDialogOpen(false);
    }, [applyTheme, loadedSettings]);
    const handleThemeSelect = useCallback(async (themeName, scope) => {
        try {
            const mergedCustomThemes = {
                ...(loadedSettings.user.settings.ui?.customThemes || {}),
                ...(loadedSettings.workspace.settings.ui?.customThemes || {}),
            };
            // Only allow selecting themes available in the merged custom themes or built-in themes
            const isBuiltIn = themeManager.findThemeByName(themeName);
            const isCustom = themeName && mergedCustomThemes[themeName];
            if (!isBuiltIn && !isCustom) {
                setThemeError(`Theme "${themeName}" not found in selected scope.`);
                setIsThemeDialogOpen(true);
                return;
            }
            loadedSettings.setValue(scope, 'ui.theme', themeName); // Update the merged settings
            if (loadedSettings.merged.ui.customThemes) {
                themeManager.loadCustomThemes(loadedSettings.merged.ui.customThemes);
            }
            applyTheme(loadedSettings.merged.ui.theme); // Apply the current theme
            refreshStatic();
            setThemeError(null);
        }
        finally {
            setIsThemeDialogOpen(false); // Close the dialog
        }
    }, [applyTheme, loadedSettings, refreshStatic, setThemeError]);
    return {
        isThemeDialogOpen,
        openThemeDialog,
        closeThemeDialog,
        handleThemeSelect,
        handleThemeHighlight,
    };
};
//# sourceMappingURL=useThemeCommand.js.map