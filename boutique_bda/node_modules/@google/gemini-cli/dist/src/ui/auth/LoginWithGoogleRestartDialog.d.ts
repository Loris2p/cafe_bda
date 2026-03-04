/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type Config } from '@google/gemini-cli-core';
interface LoginWithGoogleRestartDialogProps {
    onDismiss: () => void;
    config: Config;
}
export declare const LoginWithGoogleRestartDialog: ({ onDismiss, config, }: LoginWithGoogleRestartDialogProps) => import("react/jsx-runtime").JSX.Element;
export {};
