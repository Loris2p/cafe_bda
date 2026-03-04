/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
interface SessionRetentionWarningDialogProps {
    onKeep120Days: () => void;
    onKeep30Days: () => void;
    sessionsToDeleteCount: number;
}
export declare const SessionRetentionWarningDialog: ({ onKeep120Days, onKeep30Days, sessionsToDeleteCount, }: SessionRetentionWarningDialogProps) => import("react/jsx-runtime").JSX.Element;
export {};
