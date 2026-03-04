/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { HistoryItemWithoutId } from '../types.js';
import type { AnsiOutput, Config, GeminiClient } from '@google/gemini-cli-core';
import { type PartListUnion } from '@google/genai';
import type { UseHistoryManagerReturn } from './useHistoryManager.js';
import { type BackgroundShell } from './shellReducer.js';
export { type BackgroundShell };
export declare const OUTPUT_UPDATE_INTERVAL_MS = 1000;
/**
 * Hook to process shell commands.
 * Orchestrates command execution and updates history and agent context.
 */
export declare const useShellCommandProcessor: (addItemToHistory: UseHistoryManagerReturn["addItem"], setPendingHistoryItem: React.Dispatch<React.SetStateAction<HistoryItemWithoutId | null>>, onExec: (command: Promise<void>) => void, onDebugMessage: (message: string) => void, config: Config, geminiClient: GeminiClient, setShellInputFocused: (value: boolean) => void, terminalWidth?: number, terminalHeight?: number, activeToolPtyId?: number, isWaitingForConfirmation?: boolean) => {
    handleShellCommand: (rawQuery: PartListUnion, abortSignal: AbortSignal) => boolean;
    activeShellPtyId: number | null;
    lastShellOutputTime: number;
    backgroundShellCount: number;
    isBackgroundShellVisible: boolean;
    toggleBackgroundShell: () => void;
    backgroundCurrentShell: () => void;
    registerBackgroundShell: (pid: number, command: string, initialOutput: string | AnsiOutput) => void;
    dismissBackgroundShell: (pid: number) => void;
    backgroundShells: Map<number, BackgroundShell>;
};
