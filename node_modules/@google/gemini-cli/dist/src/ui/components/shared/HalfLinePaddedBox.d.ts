/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type React from 'react';
export interface HalfLinePaddedBoxProps {
    /**
     * The base color to blend with the terminal background.
     */
    backgroundBaseColor: string;
    /**
     * The opacity (0-1) for blending the backgroundBaseColor onto the terminal background.
     */
    backgroundOpacity: number;
    /**
     * Whether to render the solid background color.
     */
    useBackgroundColor?: boolean;
    children: React.ReactNode;
}
/**
 * A container component that renders a solid background with half-line padding
 * at the top and bottom using block characters (▀/▄).
 */
export declare const HalfLinePaddedBox: React.FC<HalfLinePaddedBoxProps>;
