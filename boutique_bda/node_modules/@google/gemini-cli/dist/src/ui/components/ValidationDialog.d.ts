/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import { type ValidationIntent } from '@google/gemini-cli-core';
interface ValidationDialogProps {
    validationLink?: string;
    validationDescription?: string;
    learnMoreUrl?: string;
    onChoice: (choice: ValidationIntent) => void;
}
export declare function ValidationDialog({ validationLink, learnMoreUrl, onChoice, }: ValidationDialogProps): React.JSX.Element;
export {};
