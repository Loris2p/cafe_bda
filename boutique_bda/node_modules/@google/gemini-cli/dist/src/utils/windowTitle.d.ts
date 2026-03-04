/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { StreamingState } from '../ui/types.js';
export interface TerminalTitleOptions {
    streamingState: StreamingState;
    thoughtSubject?: string;
    isConfirming: boolean;
    isSilentWorking: boolean;
    folderName: string;
    showThoughts: boolean;
    useDynamicTitle: boolean;
}
/**
 * Computes the dynamic terminal window title based on the current CLI state.
 *
 * @param options - The current state of the CLI and environment context
 * @returns A formatted string padded to 80 characters for the terminal title
 */
export declare function computeTerminalTitle({ streamingState, thoughtSubject, isConfirming, isSilentWorking, folderName, showThoughts, useDynamicTitle, }: TerminalTitleOptions): string;
