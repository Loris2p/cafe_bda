/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
export declare const formatBytes: (bytes: number) => string;
/**
 * Formats a duration in milliseconds into a concise, human-readable string (e.g., "1h 5s").
 * It omits any time units that are zero.
 * @param milliseconds The duration in milliseconds.
 * @returns A formatted string representing the duration.
 */
export declare const formatDuration: (milliseconds: number) => string;
export declare const formatTimeAgo: (date: string | number | Date) => string;
/**
 * Removes content bounded by reference content markers from the given text.
 * The markers are "${REFERENCE_CONTENT_START}" and "${REFERENCE_CONTENT_END}".
 *
 * @param text The input text containing potential reference blocks.
 * @returns The text with reference blocks removed and trimmed.
 */
export declare function stripReferenceContent(text: string): string;
export declare const formatResetTime: (resetTime: string) => string;
