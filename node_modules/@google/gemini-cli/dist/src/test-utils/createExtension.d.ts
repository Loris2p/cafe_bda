/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type MCPServerConfig, type ExtensionInstallMetadata, type ExtensionSetting, type CustomTheme } from '@google/gemini-cli-core';
export declare function createExtension({ extensionsDir, name, version, addContextFile, contextFileName, mcpServers, installMetadata, settings, themes, }?: {
    extensionsDir?: string | undefined;
    name?: string | undefined;
    version?: string | undefined;
    addContextFile?: boolean | undefined;
    contextFileName?: string | undefined;
    mcpServers?: Record<string, MCPServerConfig> | undefined;
    installMetadata?: ExtensionInstallMetadata | undefined;
    settings?: ExtensionSetting[] | undefined;
    themes?: CustomTheme[] | undefined;
}): string;
