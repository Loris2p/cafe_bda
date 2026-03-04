/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { CommandModule } from 'yargs';
export declare function handleList(options?: {
    outputFormat?: 'text' | 'json';
}): Promise<void>;
export declare const listCommand: CommandModule;
