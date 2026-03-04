/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { Config } from '@google/gemini-cli-core';
import type { UIActions } from '../contexts/UIActionsContext.js';
export declare function useTerminalTheme(handleThemeSelect: UIActions['handleThemeSelect'], config: Config, refreshStatic: () => void): void;
