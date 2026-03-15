/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type BackgroundShell } from './shellCommandProcessor.js';
export interface BackgroundShellManagerProps {
    backgroundShells: Map<number, BackgroundShell>;
    backgroundShellCount: number;
    isBackgroundShellVisible: boolean;
    activePtyId: number | null | undefined;
    embeddedShellFocused: boolean;
    setEmbeddedShellFocused: (focused: boolean) => void;
    terminalHeight: number;
}
export declare function useBackgroundShellManager({ backgroundShells, backgroundShellCount, isBackgroundShellVisible, activePtyId, embeddedShellFocused, setEmbeddedShellFocused, terminalHeight, }: BackgroundShellManagerProps): {
    isBackgroundShellListOpen: boolean;
    setIsBackgroundShellListOpen: import("react").Dispatch<import("react").SetStateAction<boolean>>;
    activeBackgroundShellPid: number | null;
    setActiveBackgroundShellPid: import("react").Dispatch<import("react").SetStateAction<number | null>>;
    backgroundShellHeight: number;
};
