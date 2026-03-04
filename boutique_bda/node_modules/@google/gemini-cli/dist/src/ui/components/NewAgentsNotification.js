import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { useState } from 'react';
import { Box, Text } from 'ink';
import {} from '@google/gemini-cli-core';
import { theme } from '../semantic-colors.js';
import { RadioButtonSelect, } from './shared/RadioButtonSelect.js';
import { CliSpinner } from './CliSpinner.js';
export var NewAgentsChoice;
(function (NewAgentsChoice) {
    NewAgentsChoice["ACKNOWLEDGE"] = "acknowledge";
    NewAgentsChoice["IGNORE"] = "ignore";
})(NewAgentsChoice || (NewAgentsChoice = {}));
export const NewAgentsNotification = ({ agents, onSelect, }) => {
    const [isProcessing, setIsProcessing] = useState(false);
    const options = [
        {
            label: 'Acknowledge and Enable',
            value: NewAgentsChoice.ACKNOWLEDGE,
            key: 'acknowledge',
        },
        {
            label: 'Do not enable (Ask again next time)',
            value: NewAgentsChoice.IGNORE,
            key: 'ignore',
        },
    ];
    const handleSelect = async (choice) => {
        setIsProcessing(true);
        try {
            await onSelect(choice);
        }
        finally {
            setIsProcessing(false);
        }
    };
    // Limit display to 5 agents to avoid overflow, show count for rest
    const MAX_DISPLAYED_AGENTS = 5;
    const displayAgents = agents.slice(0, MAX_DISPLAYED_AGENTS);
    const remaining = agents.length - MAX_DISPLAYED_AGENTS;
    return (_jsx(Box, { flexDirection: "column", width: "100%", children: _jsxs(Box, { flexDirection: "column", borderStyle: "round", borderColor: theme.status.warning, padding: 1, marginLeft: 1, marginRight: 1, children: [_jsxs(Box, { flexDirection: "column", marginBottom: 1, children: [_jsx(Text, { bold: true, color: theme.text.primary, children: "New Agents Discovered" }), _jsx(Text, { color: theme.text.primary, children: "The following agents were found in this project. Please review them:" }), _jsxs(Box, { flexDirection: "column", marginTop: 1, borderStyle: "single", padding: 1, children: [displayAgents.map((agent) => (_jsxs(Box, { children: [_jsx(Box, { flexShrink: 0, children: _jsxs(Text, { bold: true, color: theme.text.primary, children: ["- ", agent.name, ":", ' '] }) }), _jsxs(Text, { color: theme.text.secondary, children: [" ", agent.description] })] }, agent.name))), remaining > 0 && (_jsxs(Text, { color: theme.text.secondary, children: ["... and ", remaining, " more."] }))] })] }), isProcessing ? (_jsxs(Box, { children: [_jsx(CliSpinner, {}), _jsx(Text, { color: theme.text.primary, children: " Processing..." })] })) : (_jsx(RadioButtonSelect, { items: options, onSelect: handleSelect, isFocused: true }))] }) }));
};
//# sourceMappingURL=NewAgentsNotification.js.map