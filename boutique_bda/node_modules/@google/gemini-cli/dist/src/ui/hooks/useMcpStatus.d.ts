/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type Config, MCPDiscoveryState } from '@google/gemini-cli-core';
export declare function useMcpStatus(config: Config): {
    discoveryState: MCPDiscoveryState;
    mcpServerCount: number;
    isMcpReady: boolean;
};
