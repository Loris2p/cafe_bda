/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import React from 'react';
/**
 * Represents a single tab in the TabHeader.
 */
export interface Tab {
    /** Unique identifier for this tab */
    key: string;
    /** Header text displayed in the tab indicator */
    header: string;
    /** Optional custom status icon for this tab */
    statusIcon?: string;
    /** Whether this is a special tab (like "Review") - uses different default icon */
    isSpecial?: boolean;
}
/**
 * Props for the TabHeader component.
 */
export interface TabHeaderProps {
    /** Array of tab definitions */
    tabs: Tab[];
    /** Currently active tab index */
    currentIndex: number;
    /** Set of indices for tabs that show a completion indicator */
    completedIndices?: Set<number>;
    /** Show navigation arrow hints on sides (default: true) */
    showArrows?: boolean;
    /** Show status icons (checkmark/box) before tab headers (default: true) */
    showStatusIcons?: boolean;
    /**
     * Custom status icon renderer. Return undefined to use default icons.
     * Default icons: '✓' for completed, '□' for incomplete, '≡' for special tabs
     */
    renderStatusIcon?: (tab: Tab, index: number, isCompleted: boolean) => string | undefined;
}
/**
 * A header component that displays tab indicators for multi-tab interfaces.
 *
 * Renders in the format: `← Tab1 │ Tab2 │ Tab3 →`
 *
 * Features:
 * - Shows completion status (✓ or □) per tab
 * - Highlights current tab with accent color
 * - Supports special tabs (like "Review") with different icons
 * - Customizable status icons
 */
export declare function TabHeader({ tabs, currentIndex, completedIndices, showArrows, showStatusIcons, renderStatusIcon, }: TabHeaderProps): React.JSX.Element | null;
