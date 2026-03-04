/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { useState, useEffect, useMemo } from 'react';
import {} from './shellCommandProcessor.js';
export function useBackgroundShellManager({ backgroundShells, backgroundShellCount, isBackgroundShellVisible, activePtyId, embeddedShellFocused, setEmbeddedShellFocused, terminalHeight, }) {
    const [isBackgroundShellListOpen, setIsBackgroundShellListOpen] = useState(false);
    const [activeBackgroundShellPid, setActiveBackgroundShellPid] = useState(null);
    useEffect(() => {
        if (backgroundShells.size === 0) {
            if (activeBackgroundShellPid !== null) {
                setActiveBackgroundShellPid(null);
            }
            if (isBackgroundShellListOpen) {
                setIsBackgroundShellListOpen(false);
            }
        }
        else if (activeBackgroundShellPid === null ||
            !backgroundShells.has(activeBackgroundShellPid)) {
            // If active shell is closed or none selected, select the first one (last added usually, or just first in iteration)
            setActiveBackgroundShellPid(backgroundShells.keys().next().value ?? null);
        }
    }, [
        backgroundShells,
        activeBackgroundShellPid,
        backgroundShellCount,
        isBackgroundShellListOpen,
    ]);
    useEffect(() => {
        if (embeddedShellFocused) {
            const hasActiveForegroundShell = !!activePtyId;
            const hasVisibleBackgroundShell = isBackgroundShellVisible && backgroundShells.size > 0;
            if (!hasActiveForegroundShell && !hasVisibleBackgroundShell) {
                setEmbeddedShellFocused(false);
            }
        }
    }, [
        isBackgroundShellVisible,
        backgroundShells,
        embeddedShellFocused,
        backgroundShellCount,
        activePtyId,
        setEmbeddedShellFocused,
    ]);
    const backgroundShellHeight = useMemo(() => isBackgroundShellVisible && backgroundShells.size > 0
        ? Math.max(Math.floor(terminalHeight * 0.3), 5)
        : 0, [isBackgroundShellVisible, backgroundShells.size, terminalHeight]);
    return {
        isBackgroundShellListOpen,
        setIsBackgroundShellListOpen,
        activeBackgroundShellPid,
        setActiveBackgroundShellPid,
        backgroundShellHeight,
    };
}
//# sourceMappingURL=useBackgroundShellManager.js.map