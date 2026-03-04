/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { ShellExecutionHandle, ShellExecutionResult, ShellOutputEvent, ShellExecutionConfig } from '@google/gemini-cli-core';
export interface MockShellCommand {
    command: string | RegExp;
    result: Partial<ShellExecutionResult>;
    events?: ShellOutputEvent[];
}
type ShellExecutionServiceExecute = (commandToExecute: string, cwd: string, onOutputEvent: (event: ShellOutputEvent) => void, abortSignal: AbortSignal, shouldUseNodePty: boolean, shellExecutionConfig: ShellExecutionConfig) => Promise<ShellExecutionHandle>;
export declare class MockShellExecutionService {
    private static mockCommands;
    private static originalExecute;
    private static passthroughEnabled;
    /**
     * Registers the original implementation to allow falling back to real shell execution.
     */
    static setOriginalImplementation(implementation: ShellExecutionServiceExecute): void;
    /**
     * Enables or disables passthrough to the real implementation when no mock matches.
     */
    static setPassthrough(enabled: boolean): void;
    static setMockCommands(commands: MockShellCommand[]): void;
    static reset(): void;
    static execute(commandToExecute: string, cwd: string, onOutputEvent: (event: ShellOutputEvent) => void, abortSignal: AbortSignal, shouldUseNodePty: boolean, shellExecutionConfig: ShellExecutionConfig): Promise<ShellExecutionHandle>;
    static writeToPty: import("vitest").Mock<(...args: any[]) => any>;
    static isPtyActive: import("vitest").Mock<() => boolean>;
    static onExit: import("vitest").Mock<() => () => void>;
    static kill: import("vitest").Mock<(...args: any[]) => any>;
    static background: import("vitest").Mock<(...args: any[]) => any>;
    static subscribe: import("vitest").Mock<() => () => void>;
    static resizePty: import("vitest").Mock<(...args: any[]) => any>;
    static scrollPty: import("vitest").Mock<(...args: any[]) => any>;
}
export {};
