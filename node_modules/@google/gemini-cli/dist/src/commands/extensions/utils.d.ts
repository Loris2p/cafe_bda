/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { ExtensionManager } from '../../config/extension-manager.js';
import { type ResolvedExtensionSetting } from '@google/gemini-cli-core';
import type { ExtensionConfig } from '../../config/extension.js';
import { type ExtensionSetting, ExtensionSettingScope } from '../../config/extensions/extensionSettings.js';
export interface ConfigLogger {
    log(message: string): void;
    error(message: string): void;
}
export type RequestSettingCallback = (setting: ExtensionSetting) => Promise<string>;
export type RequestConfirmationCallback = (message: string) => Promise<boolean>;
export declare function getExtensionManager(): Promise<ExtensionManager>;
export declare function getExtensionAndManager(extensionManager: ExtensionManager, name: string, logger?: ConfigLogger): Promise<{
    extension: null;
} | {
    extension: import("@google/gemini-cli-core").GeminiCLIExtension;
}>;
export declare function configureSpecificSetting(extensionManager: ExtensionManager, extensionName: string, settingKey: string, scope: ExtensionSettingScope, logger?: ConfigLogger, requestSetting?: RequestSettingCallback): Promise<void>;
export declare function configureExtension(extensionManager: ExtensionManager, extensionName: string, scope: ExtensionSettingScope, logger?: ConfigLogger, requestSetting?: RequestSettingCallback, requestConfirmation?: RequestConfirmationCallback): Promise<void>;
export declare function configureAllExtensions(extensionManager: ExtensionManager, scope: ExtensionSettingScope, logger?: ConfigLogger, requestSetting?: RequestSettingCallback, requestConfirmation?: RequestConfirmationCallback): Promise<void>;
export declare function configureExtensionSettings(extensionConfig: ExtensionConfig, extensionId: string, scope: ExtensionSettingScope, logger?: ConfigLogger, requestSetting?: RequestSettingCallback, requestConfirmation?: RequestConfirmationCallback): Promise<void>;
export declare function getFormattedSettingValue(setting: ResolvedExtensionSetting): string;
