import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { Box, Text } from 'ink';
import { theme } from '../semantic-colors.js';
import { RadioButtonSelect, } from './shared/RadioButtonSelect.js';
export const SessionRetentionWarningDialog = ({ onKeep120Days, onKeep30Days, sessionsToDeleteCount, }) => {
    const options = [
        {
            label: 'Keep for 30 days (Recommended)',
            value: onKeep30Days,
            key: '30days',
            sublabel: `${sessionsToDeleteCount} session${sessionsToDeleteCount === 1 ? '' : 's'} will be deleted`,
        },
        {
            label: 'Keep for 120 days',
            value: onKeep120Days,
            key: '120days',
            sublabel: 'No sessions will be deleted at this time',
        },
    ];
    return (_jsxs(Box, { borderStyle: "round", borderColor: theme.border.default, flexDirection: "column", width: "100%", padding: 1, children: [_jsx(Box, { marginBottom: 1, justifyContent: "center", width: "100%", children: _jsx(Text, { bold: true, children: "Keep chat history" }) }), _jsx(Box, { flexDirection: "column", gap: 1, marginBottom: 1, children: _jsx(Text, { children: "To keep your workspace clean, we are introducing a limit on how long chat sessions are stored. Please choose a retention period for your existing chats:" }) }), _jsx(Box, { marginTop: 1, children: _jsx(RadioButtonSelect, { items: options, onSelect: (action) => action(), initialIndex: 1 }) }), _jsx(Box, { marginTop: 1, children: _jsxs(Text, { color: theme.text.secondary, children: ["Set a custom limit ", _jsx(Text, { color: theme.text.primary, children: "/settings" }), ' ', "and change \"Keep chat history\"."] }) })] }));
};
//# sourceMappingURL=SessionRetentionWarningDialog.js.map