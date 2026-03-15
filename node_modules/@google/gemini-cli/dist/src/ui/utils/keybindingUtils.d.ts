/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type Command, type KeyBinding, type KeyBindingConfig } from '../../config/keyBindings.js';
/**
 * Formats a single KeyBinding into a human-readable string (e.g., "Ctrl+C").
 */
export declare function formatKeyBinding(binding: KeyBinding): string;
/**
 * Formats the primary keybinding for a command.
 */
export declare function formatCommand(command: Command, config?: KeyBindingConfig): string;
