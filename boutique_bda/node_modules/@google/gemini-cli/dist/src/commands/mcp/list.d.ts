/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { CommandModule } from 'yargs';
import { type MergedSettings } from '../../config/settings.js';
import type { MCPServerConfig } from '@google/gemini-cli-core';
export declare function getMcpServersFromConfig(settings?: MergedSettings): Promise<{
    mcpServers: Record<string, MCPServerConfig>;
    blockedServerNames: string[];
}>;
export declare function listMcpServers(settings?: MergedSettings): Promise<void>;
interface ListArgs {
    settings?: MergedSettings;
}
export declare const listCommand: CommandModule<object, ListArgs>;
export {};
