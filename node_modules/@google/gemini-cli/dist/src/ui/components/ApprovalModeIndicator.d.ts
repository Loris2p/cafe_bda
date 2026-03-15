/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import { ApprovalMode } from '@google/gemini-cli-core';
interface ApprovalModeIndicatorProps {
    approvalMode: ApprovalMode;
    allowPlanMode?: boolean;
}
export declare const APPROVAL_MODE_TEXT: {
    AUTO_EDIT: string;
    PLAN: string;
    YOLO: string;
    HINT_SWITCH_TO_PLAN_MODE: string;
    HINT_SWITCH_TO_MANUAL_MODE: string;
    HINT_SWITCH_TO_AUTO_EDIT_MODE: string;
    HINT_SWITCH_TO_YOLO_MODE: string;
};
export declare const ApprovalModeIndicator: React.FC<ApprovalModeIndicatorProps>;
export {};
