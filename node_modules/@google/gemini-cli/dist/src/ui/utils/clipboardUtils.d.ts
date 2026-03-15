/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Supported image file extensions based on Gemini API.
 * See: https://ai.google.dev/gemini-api/docs/image-understanding
 */
export declare const IMAGE_EXTENSIONS: string[];
/**
 * Checks if the system clipboard contains an image (macOS, Windows, and Linux)
 * @returns true if clipboard contains an image
 */
export declare function clipboardHasImage(): Promise<boolean>;
/**
 * Saves the image from clipboard to a temporary file (macOS, Windows, and Linux)
 * @param targetDir The target directory to create temp files within
 * @returns The path to the saved image file, or null if no image or error
 */
export declare function saveClipboardImage(targetDir: string): Promise<string | null>;
/**
 * Cleans up old temporary clipboard image files
 * Removes files older than 1 hour
 * @param targetDir The target directory where temp files are stored
 */
export declare function cleanupOldClipboardImages(targetDir: string): Promise<void>;
/**
 * Splits a pasted text block up into escaped path segements if it's a legal
 * drag-and-drop string.
 *
 * There are multiple ways drag-and-drop paths might be escaped:
 *  - Bare (only if there are no special chars): /path/to/myfile.png
 *  - Wrapped in double quotes (Windows only): "/path/to/my file~!.png"
 *  - Escaped with backslashes (POSIX only): /path/to/my\ file~!.png
 *  - Wrapped in single quotes: '/path/to/my file~!.png'
 *
 * When wrapped in single quotes, actual single quotes in the filename are
 * escaped with "'\''". For example: '/path/to/my '\''fancy file'\''.png'
 *
 * When wrapped in double quotes, actual double quotes are not an issue becuase
 * windows doesn't allow them in filenames.
 *
 * On all systems, a single drag-and-drop may include both wrapped and bare
 * paths, so we need to handle both simultaneously.
 *
 * @param text
 * @returns An iterable of escaped paths
 */
export declare function splitDragAndDropPaths(text: string): Generator<string>;
/**
 * Processes pasted text containing file paths (like those from drag and drop),
 * adding @ prefix to valid paths and escaping them in a standard way.
 *
 * @param text The pasted text
 * @returns Processed string with @ prefixes or null if any paths are invalid
 */
export declare function parsePastedPaths(text: string): string | null;
