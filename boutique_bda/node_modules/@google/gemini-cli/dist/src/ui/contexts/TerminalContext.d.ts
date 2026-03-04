/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
export type TerminalEventHandler = (event: string) => void;
interface TerminalContextValue {
    subscribe: (handler: TerminalEventHandler) => void;
    unsubscribe: (handler: TerminalEventHandler) => void;
    queryTerminalBackground: () => Promise<void>;
}
export declare function useTerminalContext(): TerminalContextValue;
export declare function TerminalProvider({ children }: {
    children: React.ReactNode;
}): import("react/jsx-runtime").JSX.Element;
export {};
