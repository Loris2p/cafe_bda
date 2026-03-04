/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
export type ChecklistStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled';
export interface ChecklistItemData {
    status: ChecklistStatus;
    label: string;
}
export interface ChecklistItemProps {
    item: ChecklistItemData;
    wrap?: 'truncate';
    role?: 'listitem';
}
export declare const ChecklistItem: React.FC<ChecklistItemProps>;
