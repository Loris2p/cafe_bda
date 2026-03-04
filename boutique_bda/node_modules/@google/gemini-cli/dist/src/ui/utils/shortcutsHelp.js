/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { Command, keyMatchers } from '../keyMatchers.js';
export function shouldDismissShortcutsHelpOnHotkey(key) {
    return Object.values(Command).some((command) => keyMatchers[command](key));
}
//# sourceMappingURL=shortcutsHelp.js.map