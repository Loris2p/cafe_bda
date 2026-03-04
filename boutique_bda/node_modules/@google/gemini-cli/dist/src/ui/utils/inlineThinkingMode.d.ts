/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { LoadedSettings } from '../../config/settings.js';
export type InlineThinkingMode = 'off' | 'full';
export declare function getInlineThinkingMode(settings: LoadedSettings): InlineThinkingMode;
