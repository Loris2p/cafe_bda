import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box } from 'ink';
import { MarkdownDisplay } from '../../utils/MarkdownDisplay.js';
import { ShowMoreLines } from '../ShowMoreLines.js';
import { useUIState } from '../../contexts/UIStateContext.js';
import { useAlternateBuffer } from '../../hooks/useAlternateBuffer.js';
/*
 * Gemini message content is a semi-hacked component. The intention is to represent a partial
 * of GeminiMessage and is only used when a response gets too long. In that instance messages
 * are split into multiple GeminiMessageContent's to enable the root <Static> component in
 * App.tsx to be as performant as humanly possible.
 */
export const GeminiMessageContent = ({ text, isPending, availableTerminalHeight, terminalWidth, }) => {
    const { renderMarkdown } = useUIState();
    const isAlternateBuffer = useAlternateBuffer();
    const originalPrefix = '✦ ';
    const prefixWidth = originalPrefix.length;
    return (_jsxs(Box, { flexDirection: "column", paddingLeft: prefixWidth, children: [_jsx(MarkdownDisplay, { text: text, isPending: isPending, availableTerminalHeight: isAlternateBuffer || availableTerminalHeight === undefined
                    ? undefined
                    : Math.max(availableTerminalHeight - 1, 1), terminalWidth: Math.max(terminalWidth - prefixWidth, 0), renderMarkdown: renderMarkdown }), _jsx(Box, { marginTop: isAlternateBuffer ? 0 : 1, marginBottom: isAlternateBuffer ? 1 : 0, children: _jsx(ShowMoreLines, { constrainHeight: availableTerminalHeight !== undefined }) })] }));
};
//# sourceMappingURL=GeminiMessageContent.js.map