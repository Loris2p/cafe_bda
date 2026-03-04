/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
interface UseSuspendProps {
    handleWarning: (message: string) => void;
    setRawMode: (mode: boolean) => void;
    refreshStatic: () => void;
    setForceRerenderKey: (updater: (prev: number) => number) => void;
    shouldUseAlternateScreen: boolean;
}
export declare function useSuspend({ handleWarning, setRawMode, refreshStatic, setForceRerenderKey, shouldUseAlternateScreen, }: UseSuspendProps): {
    handleSuspend: () => void;
};
export {};
