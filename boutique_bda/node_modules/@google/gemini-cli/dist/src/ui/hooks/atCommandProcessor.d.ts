/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { PartListUnion } from '@google/genai';
import type { Config } from '@google/gemini-cli-core';
import type { UseHistoryManagerReturn } from './useHistoryManager.js';
/**
 * Regex source for the path/command part of an @ reference.
 * It uses strict ASCII whitespace delimiters to allow Unicode characters like NNBSP in filenames.
 *
 * 1. "(?:[^"]*)" matches a double-quoted string (for Windows paths with spaces).
 * 2. \\. matches any escaped character (e.g., \ ).
 * 3. [^ \t\n\r,;!?()\[\]{}.] matches any character that is NOT a delimiter and NOT a period.
 * 4. \.(?!$|[ \t\n\r]) matches a period ONLY if it is NOT followed by whitespace or end-of-string.
 */
export declare const AT_COMMAND_PATH_REGEX_SOURCE = "(?:(?:\"(?:[^\"]*)\")|(?:\\\\.|[^ \\t\\n\\r,;!?()\\[\\]{}.]|\\.(?!$|[ \\t\\n\\r])))+";
interface HandleAtCommandParams {
    query: string;
    config: Config;
    addItem: UseHistoryManagerReturn['addItem'];
    onDebugMessage: (message: string) => void;
    messageId: number;
    signal: AbortSignal;
}
interface HandleAtCommandResult {
    processedQuery: PartListUnion | null;
    error?: string;
}
/**
 * Checks if the query contains any file paths that require read permission.
 * Returns an array of such paths.
 */
export declare function checkPermissions(query: string, config: Config): Promise<string[]>;
/**
 * Processes user input containing one or more '@<path>' commands.
 * - Workspace paths are read via the 'read_many_files' tool.
 * - MCP resource URIs are read via each server's `resources/read`.
 * The user query is updated with inline content blocks so the LLM receives the
 * referenced context directly.
 *
 * @returns An object indicating whether the main hook should proceed with an
 *          LLM call and the processed query parts (including file/resource content).
 */
export declare function handleAtCommand({ query, config, addItem, onDebugMessage, messageId: userMessageTimestamp, signal, }: HandleAtCommandParams): Promise<HandleAtCommandResult>;
export {};
