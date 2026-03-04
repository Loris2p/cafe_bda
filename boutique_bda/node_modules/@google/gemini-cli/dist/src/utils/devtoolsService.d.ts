/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { Config } from '@google/gemini-cli-core';
/**
 * Initializes the activity logger.
 * Interception starts immediately in buffering mode.
 * If an existing DevTools server is found, attaches transport eagerly.
 */
export declare function setupInitialActivityLogger(config: Config): Promise<void>;
/**
 * Starts the DevTools server and opens the UI in the browser.
 * Returns the URL to the DevTools UI.
 * Deduplicates concurrent calls — returns the same promise if already in flight.
 */
export declare function startDevToolsServer(config: Config): Promise<string>;
/**
 * Handles the F12 key toggle for the DevTools panel.
 * Starts the DevTools server, attempts to open the browser.
 * If the panel is already open, it closes it.
 * If the panel is closed:
 * - Attempts to open the browser.
 * - If browser opening is successful, the panel remains closed.
 * - If browser opening fails or is not possible, the panel is opened.
 */
export declare function toggleDevToolsPanel(config: Config, isOpen: boolean, toggle: () => void, setOpen: () => void): Promise<void>;
/** Reset module-level state — test only. */
export declare function resetForTesting(): void;
