/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Stored in JSON file - represents persistent enablement state.
 */
export interface McpServerEnablementState {
    enabled: boolean;
}
/**
 * File config format - map of server ID to enablement state.
 */
export interface McpServerEnablementConfig {
    [serverId: string]: McpServerEnablementState;
}
/**
 * For UI display - combines file and session state.
 */
export interface McpServerDisplayState {
    /** Effective state (considering session override) */
    enabled: boolean;
    /** True if disabled via --session flag */
    isSessionDisabled: boolean;
    /** True if disabled in file */
    isPersistentDisabled: boolean;
}
/**
 * Callback types for enablement checks (passed from CLI to core).
 */
export interface EnablementCallbacks {
    isSessionDisabled: (serverId: string) => boolean;
    isFileEnabled: (serverId: string) => Promise<boolean>;
}
/**
 * Result of canLoadServer check.
 */
export interface ServerLoadResult {
    allowed: boolean;
    reason?: string;
    blockType?: 'admin' | 'allowlist' | 'excludelist' | 'session' | 'enablement';
}
/**
 * Normalize a server ID to canonical lowercase form.
 */
export declare function normalizeServerId(serverId: string): string;
/**
 * Check if a server ID is in a settings list (with backward compatibility).
 * Handles case-insensitive matching and plain name fallback for ext: servers.
 */
export declare function isInSettingsList(serverId: string, list: string[]): {
    found: boolean;
    deprecationWarning?: string;
};
/**
 * Single source of truth for whether a server can be loaded.
 * Used by: isAllowedMcpServer(), connectServer(), CLI handlers, slash handlers.
 *
 * Uses callbacks instead of direct enablementManager reference to keep
 * packages/core independent of packages/cli.
 */
export declare function canLoadServer(serverId: string, config: {
    adminMcpEnabled: boolean;
    allowedList?: string[];
    excludedList?: string[];
    enablement?: EnablementCallbacks;
}): Promise<ServerLoadResult>;
/**
 * McpServerEnablementManager
 *
 * Manages the enabled/disabled state of MCP servers.
 * Uses a simplified format compared to ExtensionEnablementManager.
 * Supports both persistent (file) and session-only (in-memory) states.
 *
 * NOTE: Use getInstance() to get the singleton instance. This ensures
 * session state (sessionDisabled Set) is shared across all code paths.
 */
export declare class McpServerEnablementManager {
    private static instance;
    private readonly configFilePath;
    private readonly configDir;
    private readonly sessionDisabled;
    /**
     * Get the singleton instance.
     */
    static getInstance(): McpServerEnablementManager;
    /**
     * Reset the singleton instance (for testing only).
     */
    static resetInstance(): void;
    constructor();
    /**
     * Check if server is enabled in FILE (persistent config only).
     * Does NOT include session state.
     */
    isFileEnabled(serverName: string): Promise<boolean>;
    /**
     * Check if server is session-disabled.
     */
    isSessionDisabled(serverName: string): boolean;
    /**
     * Check effective enabled state (combines file + session).
     * Convenience method; canLoadServer() uses separate callbacks for granular blockType.
     */
    isEffectivelyEnabled(serverName: string): Promise<boolean>;
    /**
     * Enable a server persistently.
     * Removes the server from config file (defaults to enabled).
     */
    enable(serverName: string): Promise<void>;
    /**
     * Disable a server persistently.
     * Adds server to config file with enabled: false.
     */
    disable(serverName: string): Promise<void>;
    /**
     * Disable a server for current session only (in-memory).
     */
    disableForSession(serverName: string): void;
    /**
     * Clear session disable for a server.
     */
    clearSessionDisable(serverName: string): void;
    /**
     * Get display state for a specific server (for UI).
     */
    getDisplayState(serverName: string): Promise<McpServerDisplayState>;
    /**
     * Get all display states (for UI listing).
     */
    getAllDisplayStates(serverIds: string[]): Promise<Record<string, McpServerDisplayState>>;
    /**
     * Get enablement callbacks for passing to core.
     */
    getEnablementCallbacks(): EnablementCallbacks;
    /**
     * Auto-enable any disabled MCP servers by name.
     * Returns server names that were actually re-enabled.
     */
    autoEnableServers(serverNames: string[]): Promise<string[]>;
    /**
     * Read config from file asynchronously.
     */
    private readConfig;
    /**
     * Write config to file asynchronously.
     */
    private writeConfig;
}
