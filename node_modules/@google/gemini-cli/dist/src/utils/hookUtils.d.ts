/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { HookActionResult } from './hookSettings.js';
/**
 * Shared logic for building the core hook action message while allowing the
 * caller to control how each scope and its path are rendered (e.g., bolding or
 * dimming).
 */
export declare function renderHookActionFeedback(result: HookActionResult, formatScope: (label: string, path: string) => string): string;
