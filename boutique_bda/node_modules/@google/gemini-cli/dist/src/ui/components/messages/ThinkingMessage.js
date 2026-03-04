import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useMemo } from 'react';
import { Box, Text } from 'ink';
import { theme } from '../../semantic-colors.js';
import { normalizeEscapedNewlines } from '../../utils/textUtils.js';
/**
 * Renders a model's thought as a distinct bubble.
 * Leverages Ink layout for wrapping and borders.
 */
export const ThinkingMessage = ({ thought, }) => {
    const { summary, body } = useMemo(() => {
        const subject = normalizeEscapedNewlines(thought.subject).trim();
        const description = normalizeEscapedNewlines(thought.description).trim();
        if (!subject && !description) {
            return { summary: '', body: '' };
        }
        if (!subject) {
            const lines = description
                .split('\n')
                .map((l) => l.trim())
                .filter(Boolean);
            return {
                summary: lines[0] || '',
                body: lines.slice(1).join('\n'),
            };
        }
        return {
            summary: subject,
            body: description,
        };
    }, [thought]);
    if (!summary && !body) {
        return null;
    }
    return (_jsxs(Box, { width: "100%", marginBottom: 1, paddingLeft: 1, flexDirection: "column", children: [summary && (_jsx(Box, { paddingLeft: 2, children: _jsx(Text, { color: theme.text.primary, bold: true, italic: true, children: summary }) })), body && (_jsx(Box, { borderStyle: "single", borderLeft: true, borderRight: false, borderTop: false, borderBottom: false, borderColor: theme.border.default, paddingLeft: 1, children: _jsx(Text, { color: theme.text.secondary, italic: true, children: body }) }))] }));
};
//# sourceMappingURL=ThinkingMessage.js.map