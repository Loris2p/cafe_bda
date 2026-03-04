/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import type { AnsiLine, AnsiOutput } from '@google/gemini-cli-core';
interface AnsiOutputProps {
    data: AnsiOutput;
    availableTerminalHeight?: number;
    width: number;
    maxLines?: number;
    disableTruncation?: boolean;
}
export declare const AnsiOutputText: React.FC<AnsiOutputProps>;
export declare const AnsiLineText: React.FC<{
    line: AnsiLine;
}>;
export {};
