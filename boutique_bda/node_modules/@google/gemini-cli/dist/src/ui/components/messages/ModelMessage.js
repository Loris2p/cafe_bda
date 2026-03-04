import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import { Text, Box } from 'ink';
import { theme } from '../../semantic-colors.js';
import { getDisplayString } from '@google/gemini-cli-core';
export const ModelMessage = ({ model }) => (_jsx(Box, { marginLeft: 2, children: _jsxs(Text, { color: theme.ui.comment, italic: true, children: ["Responding with ", getDisplayString(model)] }) }));
//# sourceMappingURL=ModelMessage.js.map