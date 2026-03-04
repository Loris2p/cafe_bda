/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type Config } from '@google/gemini-cli-core';
import type React from 'react';
export declare const BACKSLASH_ENTER_TIMEOUT = 5;
export declare const ESC_TIMEOUT = 50;
export declare const PASTE_TIMEOUT = 30000;
export declare const FAST_RETURN_TIMEOUT = 30;
export declare enum KeypressPriority {
    Low = -100,
    Normal = 0,
    High = 100,
    Critical = 200
}
export interface Key {
    name: string;
    shift: boolean;
    alt: boolean;
    ctrl: boolean;
    cmd: boolean;
    insertable: boolean;
    sequence: string;
}
export type KeypressHandler = (key: Key) => boolean | void;
interface KeypressContextValue {
    subscribe: (handler: KeypressHandler, priority?: KeypressPriority | boolean) => void;
    unsubscribe: (handler: KeypressHandler) => void;
}
export declare function useKeypressContext(): KeypressContextValue;
export declare function KeypressProvider({ children, config, debugKeystrokeLogging, }: {
    children: React.ReactNode;
    config?: Config;
    debugKeystrokeLogging?: boolean;
}): import("react/jsx-runtime").JSX.Element;
export {};
