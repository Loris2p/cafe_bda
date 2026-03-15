/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { useEffect } from 'react';
import { useKeypressContext, } from '../contexts/KeypressContext.js';
/**
 * A hook that listens for keypress events from stdin.
 *
 * @param onKeypress - The callback function to execute on each keypress.
 * @param options - Options to control the hook's behavior.
 * @param options.isActive - Whether the hook should be actively listening for input.
 * @param options.priority - Priority level (integer or KeypressPriority enum) or boolean for backward compatibility.
 */
export function useKeypress(onKeypress, { isActive, priority, }) {
    const { subscribe, unsubscribe } = useKeypressContext();
    useEffect(() => {
        if (!isActive) {
            return;
        }
        subscribe(onKeypress, priority);
        return () => {
            unsubscribe(onKeypress);
        };
    }, [isActive, onKeypress, subscribe, unsubscribe, priority]);
}
//# sourceMappingURL=useKeypress.js.map