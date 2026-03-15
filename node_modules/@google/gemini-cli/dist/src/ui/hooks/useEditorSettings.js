/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { useState, useCallback } from 'react';
import { MessageType } from '../types.js';
import { allowEditorTypeInSandbox, hasValidEditorCommand, getEditorDisplayName, coreEvents, CoreEvent, } from '@google/gemini-cli-core';
import { SettingPaths } from '../../config/settingPaths.js';
export const useEditorSettings = (loadedSettings, setEditorError, addItem) => {
    const [isEditorDialogOpen, setIsEditorDialogOpen] = useState(false);
    const openEditorDialog = useCallback(() => {
        setIsEditorDialogOpen(true);
    }, []);
    const handleEditorSelect = useCallback((editorType, scope) => {
        if (editorType &&
            (!hasValidEditorCommand(editorType) ||
                !allowEditorTypeInSandbox(editorType))) {
            return;
        }
        try {
            loadedSettings.setValue(scope, SettingPaths.General.PreferredEditor, editorType);
            addItem({
                type: MessageType.INFO,
                text: `Editor preference ${editorType ? `set to "${getEditorDisplayName(editorType)}"` : 'cleared'} in ${scope} settings.`,
            }, Date.now());
            setEditorError(null);
            setIsEditorDialogOpen(false);
            coreEvents.emit(CoreEvent.EditorSelected, { editor: editorType });
        }
        catch (error) {
            setEditorError(`Failed to set editor preference: ${error}`);
        }
    }, [loadedSettings, setEditorError, addItem]);
    const exitEditorDialog = useCallback(() => {
        setIsEditorDialogOpen(false);
        coreEvents.emit(CoreEvent.EditorSelected, { editor: undefined });
    }, []);
    return {
        isEditorDialogOpen,
        openEditorDialog,
        handleEditorSelect,
        exitEditorDialog,
    };
};
//# sourceMappingURL=useEditorSettings.js.map