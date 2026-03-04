/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import React from 'react';
export declare const MAX_WIDTH = 150;
export interface ExpandableTextProps {
    label: string;
    matchedIndex?: number;
    userInput?: string;
    textColor?: string;
    isExpanded?: boolean;
    maxWidth?: number;
    maxLines?: number;
}
export declare const ExpandableText: React.NamedExoticComponent<ExpandableTextProps>;
