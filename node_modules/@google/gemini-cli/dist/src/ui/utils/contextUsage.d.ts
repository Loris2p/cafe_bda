/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
export declare function getContextUsagePercentage(promptTokenCount: number, model: string | undefined): number;
export declare function isContextUsageHigh(promptTokenCount: number, model: string | undefined, threshold?: number): boolean;
