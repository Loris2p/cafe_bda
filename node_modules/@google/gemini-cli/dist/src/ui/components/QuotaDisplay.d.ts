/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
interface QuotaDisplayProps {
    remaining: number | undefined;
    limit: number | undefined;
    resetTime?: string;
    terse?: boolean;
}
export declare const QuotaDisplay: React.FC<QuotaDisplayProps>;
export {};
