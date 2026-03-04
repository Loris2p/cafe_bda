/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import { type ChecklistItemData } from './ChecklistItem.js';
export interface ChecklistProps {
    title: string;
    items: ChecklistItemData[];
    isExpanded: boolean;
    toggleHint?: string;
}
export declare const Checklist: React.FC<ChecklistProps>;
