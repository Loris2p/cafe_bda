/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
export declare const APPROVAL_MODE_REVEAL_DURATION_MS = 1200;
export declare function useVisibilityToggle(): {
    cleanUiDetailsVisible: boolean;
    setCleanUiDetailsVisible: (visible: boolean) => void;
    toggleCleanUiDetailsVisible: () => void;
    revealCleanUiDetailsTemporarily: (durationMs?: number) => void;
};
