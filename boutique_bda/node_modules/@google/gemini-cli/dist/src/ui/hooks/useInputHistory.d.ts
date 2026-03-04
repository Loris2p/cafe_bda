/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
interface UseInputHistoryProps {
    userMessages: readonly string[];
    onSubmit: (value: string) => void;
    isActive: boolean;
    currentQuery: string;
    currentCursorOffset: number;
    onChange: (value: string, cursorPosition?: 'start' | 'end' | number) => void;
}
export interface UseInputHistoryReturn {
    handleSubmit: (value: string) => void;
    navigateUp: () => boolean;
    navigateDown: () => boolean;
}
export declare function useInputHistory({ userMessages, onSubmit, isActive, currentQuery, currentCursorOffset, onChange, }: UseInputHistoryProps): UseInputHistoryReturn;
export {};
