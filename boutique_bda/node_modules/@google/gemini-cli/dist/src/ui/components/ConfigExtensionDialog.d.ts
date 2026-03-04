/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import type { ExtensionManager } from '../../config/extension-manager.js';
import { type ConfigLogger } from '../../commands/extensions/utils.js';
import { ExtensionSettingScope } from '../../config/extensions/extensionSettings.js';
export interface ConfigExtensionDialogProps {
    extensionManager: ExtensionManager;
    onClose: () => void;
    extensionName?: string;
    settingKey?: string;
    scope?: ExtensionSettingScope;
    configureAll?: boolean;
    loggerAdapter: ConfigLogger;
}
export declare const ConfigExtensionDialog: React.FC<ConfigExtensionDialogProps>;
