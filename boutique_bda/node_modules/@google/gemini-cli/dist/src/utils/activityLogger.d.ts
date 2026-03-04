/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { EventEmitter } from 'node:events';
import { type ConsoleLogPayload, type Config } from '@google/gemini-cli-core';
export interface NetworkLog {
    id: string;
    timestamp: number;
    method: string;
    url: string;
    headers: Record<string, string>;
    body?: string;
    pending?: boolean;
    chunk?: {
        index: number;
        data: string;
        timestamp: number;
    };
    response?: {
        status: number;
        headers: Record<string, string>;
        body?: string;
        durationMs: number;
    };
    error?: string;
}
/** Partial update to an existing network log. */
export type PartialNetworkLog = {
    id: string;
} & Partial<NetworkLog>;
/**
 * Capture utility for session activities (network and console).
 * Provides a stream of events that can be persisted for analysis or inspection.
 */
export declare class ActivityLogger extends EventEmitter {
    private static instance;
    private isInterceptionEnabled;
    private requestStartTimes;
    private networkLoggingEnabled;
    private networkBufferMap;
    private networkBufferIds;
    private consoleBuffer;
    private readonly bufferLimit;
    static getInstance(): ActivityLogger;
    enableNetworkLogging(): void;
    disableNetworkLogging(): void;
    isNetworkLoggingEnabled(): boolean;
    /**
     * Atomically returns and clears all buffered logs.
     * Prevents data loss from events emitted between get and clear.
     */
    drainBufferedLogs(): {
        network: Array<NetworkLog | PartialNetworkLog>;
        console: Array<ConsoleLogPayload & {
            timestamp: number;
        }>;
    };
    getBufferedLogs(): {
        network: Array<NetworkLog | PartialNetworkLog>;
        console: Array<ConsoleLogPayload & {
            timestamp: number;
        }>;
    };
    clearBufferedLogs(): void;
    private stringifyHeaders;
    private sanitizeNetworkLog;
    /** @internal Emit a network event — public for testing only. */
    emitNetworkEvent(payload: NetworkLog | PartialNetworkLog): void;
    private safeEmitNetwork;
    enable(): void;
    private patchGlobalFetch;
    private patchNodeHttp;
    logConsole(payload: ConsoleLogPayload): void;
}
/**
 * Initialize the activity logger with a specific transport mode.
 *
 * @param config  CLI configuration
 * @param options Transport configuration: network (WebSocket) or file (JSONL)
 */
export declare function initActivityLogger(config: Config, options: {
    mode: 'network';
    host: string;
    port: number;
    onReconnectFailed?: () => void;
} | {
    mode: 'file';
    filePath?: string;
} | {
    mode: 'buffer';
}): void;
/**
 * Add a network (WebSocket) transport to the existing ActivityLogger singleton.
 * Used for promotion re-entry without re-bridging coreEvents.
 */
export declare function addNetworkTransport(config: Config, host: string, port: number, onReconnectFailed?: () => void): void;
