/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * Options for the useTabbedNavigation hook.
 */
export interface UseTabbedNavigationOptions {
    /** Total number of tabs */
    tabCount: number;
    /** Initial tab index (default: 0) */
    initialIndex?: number;
    /** Allow wrapping from last to first and vice versa (default: false) */
    wrapAround?: boolean;
    /** Whether left/right arrows navigate tabs (default: true) */
    enableArrowNavigation?: boolean;
    /** Whether Tab key advances to next tab (default: true) */
    enableTabKey?: boolean;
    /** Callback to determine if navigation is blocked (e.g., during text input) */
    isNavigationBlocked?: () => boolean;
    /** Whether the hook is active and should respond to keyboard input */
    isActive?: boolean;
    /** Callback when the active tab changes */
    onTabChange?: (index: number) => void;
}
/**
 * Result of the useTabbedNavigation hook.
 */
export interface UseTabbedNavigationResult {
    /** Current tab index */
    currentIndex: number;
    /** Set the current tab index directly */
    setCurrentIndex: (index: number) => void;
    /** Move to the next tab (respecting bounds) */
    goToNextTab: () => void;
    /** Move to the previous tab (respecting bounds) */
    goToPrevTab: () => void;
    /** Whether currently at first tab */
    isFirstTab: boolean;
    /** Whether currently at last tab */
    isLastTab: boolean;
}
/**
 * A headless hook that provides keyboard navigation for tabbed interfaces.
 *
 * Features:
 * - Keyboard navigation with left/right arrows
 * - Optional Tab key navigation
 * - Optional wrap-around navigation
 * - Navigation blocking callback (for text input scenarios)
 */
export declare function useTabbedNavigation({ tabCount, initialIndex, wrapAround, enableArrowNavigation, enableTabKey, isNavigationBlocked, isActive, onTabChange, }: UseTabbedNavigationOptions): UseTabbedNavigationResult;
