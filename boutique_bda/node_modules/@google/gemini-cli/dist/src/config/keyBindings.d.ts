/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Command enum for all available keyboard shortcuts
 */
export declare enum Command {
    RETURN = "basic.confirm",
    ESCAPE = "basic.cancel",
    QUIT = "basic.quit",
    EXIT = "basic.exit",
    HOME = "cursor.home",
    END = "cursor.end",
    MOVE_UP = "cursor.up",
    MOVE_DOWN = "cursor.down",
    MOVE_LEFT = "cursor.left",
    MOVE_RIGHT = "cursor.right",
    MOVE_WORD_LEFT = "cursor.wordLeft",
    MOVE_WORD_RIGHT = "cursor.wordRight",
    KILL_LINE_RIGHT = "edit.deleteRightAll",
    KILL_LINE_LEFT = "edit.deleteLeftAll",
    CLEAR_INPUT = "edit.clear",
    DELETE_WORD_BACKWARD = "edit.deleteWordLeft",
    DELETE_WORD_FORWARD = "edit.deleteWordRight",
    DELETE_CHAR_LEFT = "edit.deleteLeft",
    DELETE_CHAR_RIGHT = "edit.deleteRight",
    UNDO = "edit.undo",
    REDO = "edit.redo",
    SCROLL_UP = "scroll.up",
    SCROLL_DOWN = "scroll.down",
    SCROLL_HOME = "scroll.home",
    SCROLL_END = "scroll.end",
    PAGE_UP = "scroll.pageUp",
    PAGE_DOWN = "scroll.pageDown",
    HISTORY_UP = "history.previous",
    HISTORY_DOWN = "history.next",
    REVERSE_SEARCH = "history.search.start",
    SUBMIT_REVERSE_SEARCH = "history.search.submit",
    ACCEPT_SUGGESTION_REVERSE_SEARCH = "history.search.accept",
    REWIND = "history.rewind",
    NAVIGATION_UP = "nav.up",
    NAVIGATION_DOWN = "nav.down",
    DIALOG_NAVIGATION_UP = "nav.dialog.up",
    DIALOG_NAVIGATION_DOWN = "nav.dialog.down",
    DIALOG_NEXT = "nav.dialog.next",
    DIALOG_PREV = "nav.dialog.previous",
    ACCEPT_SUGGESTION = "suggest.accept",
    COMPLETION_UP = "suggest.focusPrevious",
    COMPLETION_DOWN = "suggest.focusNext",
    EXPAND_SUGGESTION = "suggest.expand",
    COLLAPSE_SUGGESTION = "suggest.collapse",
    SUBMIT = "input.submit",
    NEWLINE = "input.newline",
    OPEN_EXTERNAL_EDITOR = "input.openExternalEditor",
    PASTE_CLIPBOARD = "input.paste",
    BACKGROUND_SHELL_ESCAPE = "backgroundShellEscape",
    BACKGROUND_SHELL_SELECT = "backgroundShellSelect",
    TOGGLE_BACKGROUND_SHELL = "toggleBackgroundShell",
    TOGGLE_BACKGROUND_SHELL_LIST = "toggleBackgroundShellList",
    KILL_BACKGROUND_SHELL = "backgroundShell.kill",
    UNFOCUS_BACKGROUND_SHELL = "backgroundShell.unfocus",
    UNFOCUS_BACKGROUND_SHELL_LIST = "backgroundShell.listUnfocus",
    SHOW_BACKGROUND_SHELL_UNFOCUS_WARNING = "backgroundShell.unfocusWarning",
    SHOW_SHELL_INPUT_UNFOCUS_WARNING = "shellInput.unfocusWarning",
    SHOW_ERROR_DETAILS = "app.showErrorDetails",
    SHOW_FULL_TODOS = "app.showFullTodos",
    SHOW_IDE_CONTEXT_DETAIL = "app.showIdeContextDetail",
    TOGGLE_MARKDOWN = "app.toggleMarkdown",
    TOGGLE_COPY_MODE = "app.toggleCopyMode",
    TOGGLE_YOLO = "app.toggleYolo",
    CYCLE_APPROVAL_MODE = "app.cycleApprovalMode",
    SHOW_MORE_LINES = "app.showMoreLines",
    EXPAND_PASTE = "app.expandPaste",
    FOCUS_SHELL_INPUT = "app.focusShellInput",
    UNFOCUS_SHELL_INPUT = "app.unfocusShellInput",
    CLEAR_SCREEN = "app.clearScreen",
    RESTART_APP = "app.restart",
    SUSPEND_APP = "app.suspend"
}
/**
 * Data-driven key binding structure for user configuration
 */
export interface KeyBinding {
    /** The key name (e.g., 'a', 'return', 'tab', 'escape') */
    key: string;
    /** Shift key requirement: true=must be pressed, false=must not be pressed, undefined=ignore */
    shift?: boolean;
    /** Alt/Option key requirement: true=must be pressed, false=must not be pressed, undefined=ignore */
    alt?: boolean;
    /** Control key requirement: true=must be pressed, false=must not be pressed, undefined=ignore */
    ctrl?: boolean;
    /** Command/Windows/Super key requirement: true=must be pressed, false=must not be pressed, undefined=ignore */
    cmd?: boolean;
}
/**
 * Configuration type mapping commands to their key bindings
 */
export type KeyBindingConfig = {
    readonly [C in Command]: readonly KeyBinding[];
};
/**
 * Default key binding configuration
 * Matches the original hard-coded logic exactly
 */
export declare const defaultKeyBindings: KeyBindingConfig;
interface CommandCategory {
    readonly title: string;
    readonly commands: readonly Command[];
}
/**
 * Presentation metadata for grouping commands in documentation or UI.
 */
export declare const commandCategories: readonly CommandCategory[];
/**
 * Human-readable descriptions for each command, used in docs/tooling.
 */
export declare const commandDescriptions: Readonly<Record<Command, string>>;
export {};
