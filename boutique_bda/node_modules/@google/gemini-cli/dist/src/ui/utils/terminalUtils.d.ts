/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Returns the color depth of the current terminal.
 * Returns 24 (TrueColor) if unknown or not a TTY.
 */
export declare function getColorDepth(): number;
/**
 * Returns true if the terminal has low color depth (less than 24-bit).
 */
export declare function isLowColorDepth(): boolean;
/**
 * Returns true if the current terminal is iTerm2.
 */
export declare function isITerm2(): boolean;
/**
 * Resets the cached iTerm2 detection value.
 * Primarily used for testing.
 */
export declare function resetITerm2Cache(): void;
