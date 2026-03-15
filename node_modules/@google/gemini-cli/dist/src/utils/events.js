/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { EventEmitter } from 'node:events';
export var TransientMessageType;
(function (TransientMessageType) {
    TransientMessageType["Warning"] = "warning";
    TransientMessageType["Hint"] = "hint";
})(TransientMessageType || (TransientMessageType = {}));
export var AppEvent;
(function (AppEvent) {
    AppEvent["OpenDebugConsole"] = "open-debug-console";
    AppEvent["Flicker"] = "flicker";
    AppEvent["SelectionWarning"] = "selection-warning";
    AppEvent["PasteTimeout"] = "paste-timeout";
    AppEvent["TerminalBackground"] = "terminal-background";
    AppEvent["TransientMessage"] = "transient-message";
})(AppEvent || (AppEvent = {}));
export const appEvents = new EventEmitter();
//# sourceMappingURL=events.js.map