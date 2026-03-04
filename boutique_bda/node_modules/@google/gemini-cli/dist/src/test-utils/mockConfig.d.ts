/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { Config } from '@google/gemini-cli-core';
import type { LoadedSettings } from '../config/settings.js';
/**
 * Creates a mocked Config object with default values and allows overrides.
 */
export declare const createMockConfig: (overrides?: Partial<Config>) => Config;
/**
 * Creates a mocked LoadedSettings object for tests.
 */
export declare function createMockSettings(overrides?: Record<string, unknown>): LoadedSettings;
