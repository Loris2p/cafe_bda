/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type WorkspaceContext } from '@google/gemini-cli-core';
export declare function expandHomeDir(p: string): string;
/**
 * Gets directory suggestions based on a partial path.
 * Uses async iteration with fs.opendir for efficient handling of large directories.
 *
 * @param partialPath The partial path typed by the user.
 * @returns A promise resolving to an array of directory path suggestions.
 */
export declare function getDirectorySuggestions(partialPath: string): Promise<string[]>;
export interface BatchAddResult {
    added: string[];
    errors: string[];
}
/**
 * Helper to batch add directories to the workspace context.
 * Handles expansion and error formatting.
 */
export declare function batchAddDirectories(workspaceContext: WorkspaceContext, paths: string[]): BatchAddResult;
