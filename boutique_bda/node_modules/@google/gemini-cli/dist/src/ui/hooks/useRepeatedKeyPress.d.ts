/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
export interface UseRepeatedKeyPressOptions {
    onRepeat?: (count: number) => void;
    onReset?: () => void;
    windowMs: number;
}
export declare function useRepeatedKeyPress(options: UseRepeatedKeyPressOptions): {
    pressCount: number;
    handlePress: () => number;
    resetCount: () => void;
};
