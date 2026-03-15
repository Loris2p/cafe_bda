/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
import type { QuotaStats } from '../types.js';
interface ModelStatsDisplayProps {
    selectedAuthType?: string;
    userEmail?: string;
    tier?: string;
    currentModel?: string;
    quotaStats?: QuotaStats;
}
export declare const ModelStatsDisplay: React.FC<ModelStatsDisplayProps>;
export {};
