/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Extracts a human-readable error message specifically for ACP (IDE) clients.
 * This function recursively parses JSON error blobs that are common in
 * Google API responses but ugly to display in an IDE's UI.
 */
export declare function getAcpErrorMessage(error: unknown): string;
