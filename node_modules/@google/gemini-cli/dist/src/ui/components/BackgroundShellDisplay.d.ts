/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type BackgroundShell } from '../hooks/shellCommandProcessor.js';
interface BackgroundShellDisplayProps {
    shells: Map<number, BackgroundShell>;
    activePid: number;
    width: number;
    height: number;
    isFocused: boolean;
    isListOpenProp: boolean;
}
export declare const BackgroundShellDisplay: ({ shells, activePid, width, height, isFocused, isListOpenProp, }: BackgroundShellDisplayProps) => import("react/jsx-runtime").JSX.Element;
export {};
