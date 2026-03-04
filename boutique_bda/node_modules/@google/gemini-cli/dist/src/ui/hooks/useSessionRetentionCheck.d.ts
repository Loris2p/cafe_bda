/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type Config } from '@google/gemini-cli-core';
import { type Settings } from '../../config/settings.js';
export declare function useSessionRetentionCheck(config: Config, settings: Settings, onAutoEnable?: () => void): {
    shouldShowWarning: boolean;
    checkComplete: boolean;
    sessionsToDeleteCount: number;
};
