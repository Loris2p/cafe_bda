import { Fragment as _Fragment, jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useMemo } from 'react';
import { Box, Text, useIsScreenReaderEnabled } from 'ink';
import { useUIState } from '../../contexts/UIStateContext.js';
import { theme } from '../../semantic-colors.js';
import { interpolateColor, resolveColor, getSafeLowColorBackground, } from '../../themes/color-utils.js';
import { isLowColorDepth, isITerm2 } from '../../utils/terminalUtils.js';
/**
 * A container component that renders a solid background with half-line padding
 * at the top and bottom using block characters (▀/▄).
 */
export const HalfLinePaddedBox = (props) => {
    const isScreenReaderEnabled = useIsScreenReaderEnabled();
    if (props.useBackgroundColor === false || isScreenReaderEnabled) {
        return _jsx(_Fragment, { children: props.children });
    }
    return _jsx(HalfLinePaddedBoxInternal, { ...props });
};
const HalfLinePaddedBoxInternal = ({ backgroundBaseColor, backgroundOpacity, children, }) => {
    const { terminalWidth } = useUIState();
    const terminalBg = theme.background.primary || 'black';
    const isLowColor = isLowColorDepth();
    const backgroundColor = useMemo(() => {
        // Interpolated background colors often look bad in 256-color terminals
        if (isLowColor) {
            return getSafeLowColorBackground(terminalBg);
        }
        const resolvedBase = resolveColor(backgroundBaseColor) || backgroundBaseColor;
        const resolvedTerminalBg = resolveColor(terminalBg) || terminalBg;
        return interpolateColor(resolvedTerminalBg, resolvedBase, backgroundOpacity);
    }, [backgroundBaseColor, backgroundOpacity, terminalBg, isLowColor]);
    if (!backgroundColor) {
        return _jsx(_Fragment, { children: children });
    }
    const isITerm = isITerm2();
    if (isITerm) {
        return (_jsxs(Box, { width: terminalWidth, flexDirection: "column", alignItems: "stretch", minHeight: 1, flexShrink: 0, children: [_jsx(Box, { width: terminalWidth, flexDirection: "row", children: _jsx(Text, { color: backgroundColor, children: '▄'.repeat(terminalWidth) }) }), _jsx(Box, { width: terminalWidth, flexDirection: "column", alignItems: "stretch", backgroundColor: backgroundColor, children: children }), _jsx(Box, { width: terminalWidth, flexDirection: "row", children: _jsx(Text, { color: backgroundColor, children: '▀'.repeat(terminalWidth) }) })] }));
    }
    return (_jsxs(Box, { width: terminalWidth, flexDirection: "column", alignItems: "stretch", minHeight: 1, flexShrink: 0, backgroundColor: backgroundColor, children: [_jsx(Box, { width: terminalWidth, flexDirection: "row", children: _jsx(Text, { backgroundColor: backgroundColor, color: terminalBg, children: '▀'.repeat(terminalWidth) }) }), children, _jsx(Box, { width: terminalWidth, flexDirection: "row", children: _jsx(Text, { color: terminalBg, backgroundColor: backgroundColor, children: '▄'.repeat(terminalWidth) }) })] }));
};
//# sourceMappingURL=HalfLinePaddedBox.js.map