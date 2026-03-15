/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
interface QuotaStatsInfoProps {
    remaining: number | undefined;
    limit: number | undefined;
    resetTime?: string;
    showDetails?: boolean;
}
export declare const QuotaStatsInfo: React.FC<QuotaStatsInfoProps>;
export {};
