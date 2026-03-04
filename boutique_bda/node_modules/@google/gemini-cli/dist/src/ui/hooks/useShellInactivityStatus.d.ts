/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { StreamingState } from '../types.js';
import { type TrackedToolCall } from './useToolScheduler.js';
interface ShellInactivityStatusProps {
    activePtyId: number | string | null | undefined;
    lastOutputTime: number;
    streamingState: StreamingState;
    pendingToolCalls: TrackedToolCall[];
    embeddedShellFocused: boolean;
    isInteractiveShellEnabled: boolean;
}
export type InactivityStatus = 'none' | 'action_required' | 'silent_working';
export interface ShellInactivityStatus {
    shouldShowFocusHint: boolean;
    inactivityStatus: InactivityStatus;
}
/**
 * Consolidated hook to manage all shell-related inactivity states.
 * Centralizes the timing heuristics and redirection suppression logic.
 */
export declare const useShellInactivityStatus: ({ activePtyId, lastOutputTime, streamingState, pendingToolCalls, embeddedShellFocused, isInteractiveShellEnabled, }: ShellInactivityStatusProps) => ShellInactivityStatus;
export {};
