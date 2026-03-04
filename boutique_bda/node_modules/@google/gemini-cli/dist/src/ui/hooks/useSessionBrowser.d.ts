/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { HistoryItemWithoutId } from '../types.js';
import type { Config, ResumedSessionData } from '@google/gemini-cli-core';
import type { SessionInfo } from '../../utils/sessionUtils.js';
import { convertSessionToHistoryFormats } from '../../utils/sessionUtils.js';
import type { Part } from '@google/genai';
export { convertSessionToHistoryFormats };
export declare const useSessionBrowser: (config: Config, onLoadHistory: (uiHistory: HistoryItemWithoutId[], clientHistory: Array<{
    role: "user" | "model";
    parts: Part[];
}>, resumedSessionData: ResumedSessionData) => Promise<void>) => {
    isSessionBrowserOpen: boolean;
    openSessionBrowser: () => void;
    closeSessionBrowser: () => void;
    /**
     * Loads a conversation by ID, and reinitializes the chat recording service with it.
     */
    handleResumeSession: (session: SessionInfo) => Promise<void>;
    /**
     * Deletes a session by ID using the ChatRecordingService.
     */
    handleDeleteSession: (session: SessionInfo) => void;
};
