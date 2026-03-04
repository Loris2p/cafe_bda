/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { AnsiOutput } from '@google/gemini-cli-core';
export interface BackgroundShell {
    pid: number;
    command: string;
    output: string | AnsiOutput;
    isBinary: boolean;
    binaryBytesReceived: number;
    status: 'running' | 'exited';
    exitCode?: number;
}
export interface ShellState {
    activeShellPtyId: number | null;
    lastShellOutputTime: number;
    backgroundShells: Map<number, BackgroundShell>;
    isBackgroundShellVisible: boolean;
}
export type ShellAction = {
    type: 'SET_ACTIVE_PTY';
    pid: number | null;
} | {
    type: 'SET_OUTPUT_TIME';
    time: number;
} | {
    type: 'SET_VISIBILITY';
    visible: boolean;
} | {
    type: 'TOGGLE_VISIBILITY';
} | {
    type: 'REGISTER_SHELL';
    pid: number;
    command: string;
    initialOutput: string | AnsiOutput;
} | {
    type: 'UPDATE_SHELL';
    pid: number;
    update: Partial<BackgroundShell>;
} | {
    type: 'APPEND_SHELL_OUTPUT';
    pid: number;
    chunk: string | AnsiOutput;
} | {
    type: 'SYNC_BACKGROUND_SHELLS';
} | {
    type: 'DISMISS_SHELL';
    pid: number;
};
export declare const initialState: ShellState;
export declare function shellReducer(state: ShellState, action: ShellAction): ShellState;
