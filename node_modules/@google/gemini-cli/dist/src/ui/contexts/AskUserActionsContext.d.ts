/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import type { Question } from '@google/gemini-cli-core';
export interface AskUserState {
    questions: Question[];
    correlationId: string;
}
interface AskUserActionsContextValue {
    /** Current ask_user request, or null if no dialog should be shown */
    request: AskUserState | null;
    /** Submit answers - publishes ASK_USER_RESPONSE to message bus */
    submit: (answers: {
        [questionIndex: string]: string;
    }) => Promise<void>;
    /** Cancel the dialog - clears request state */
    cancel: () => void;
}
export declare const AskUserActionsContext: React.Context<AskUserActionsContextValue | null>;
export declare const useAskUserActions: () => AskUserActionsContextValue;
interface AskUserActionsProviderProps {
    children: React.ReactNode;
    /** Current ask_user request state (managed by AppContainer) */
    request: AskUserState | null;
    /** Handler to submit answers */
    onSubmit: (answers: {
        [questionIndex: string]: string;
    }) => Promise<void>;
    /** Handler to cancel the dialog */
    onCancel: () => void;
}
/**
 * Provides ask_user dialog state and actions to child components.
 *
 * State is managed by AppContainer (which subscribes to the message bus)
 * and passed here as props. This follows the same pattern as ToolActionsProvider.
 */
export declare const AskUserActionsProvider: React.FC<AskUserActionsProviderProps>;
export {};
