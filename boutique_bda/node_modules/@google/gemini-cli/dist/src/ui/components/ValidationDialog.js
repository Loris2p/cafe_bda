import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useState, useEffect, useCallback } from 'react';
import { Box, Text } from 'ink';
import { RadioButtonSelect } from './shared/RadioButtonSelect.js';
import { theme } from '../semantic-colors.js';
import { CliSpinner } from './CliSpinner.js';
import { openBrowserSecurely, shouldLaunchBrowser, } from '@google/gemini-cli-core';
import { useKeypress } from '../hooks/useKeypress.js';
import { keyMatchers, Command } from '../keyMatchers.js';
export function ValidationDialog({ validationLink, learnMoreUrl, onChoice, }) {
    const [state, setState] = useState('choosing');
    const [errorMessage, setErrorMessage] = useState('');
    const items = [
        {
            label: 'Verify your account',
            value: 'verify',
            key: 'verify',
        },
        {
            label: 'Change authentication',
            value: 'change_auth',
            key: 'change_auth',
        },
    ];
    // Handle keypresses globally for cancellation, and specific logic for waiting state
    useKeypress((key) => {
        if (keyMatchers[Command.ESCAPE](key) || keyMatchers[Command.QUIT](key)) {
            onChoice('cancel');
            return true;
        }
        else if (state === 'waiting' && keyMatchers[Command.RETURN](key)) {
            // User confirmed verification is complete - transition to 'complete' state
            setState('complete');
            return true;
        }
        return false;
    }, { isActive: state !== 'complete' });
    // When state becomes 'complete', show success message briefly then proceed
    useEffect(() => {
        if (state === 'complete') {
            const timer = setTimeout(() => {
                onChoice('verify');
            }, 500);
            return () => clearTimeout(timer);
        }
        return undefined;
    }, [state, onChoice]);
    const handleSelect = useCallback(async (choice) => {
        if (choice === 'verify') {
            if (validationLink) {
                // Check if we're in an environment where we can launch a browser
                if (!shouldLaunchBrowser()) {
                    // In headless mode, show the link and wait for user to manually verify
                    setErrorMessage(`Please open this URL in a browser: ${validationLink}`);
                    setState('waiting');
                    return;
                }
                try {
                    await openBrowserSecurely(validationLink);
                    setState('waiting');
                }
                catch (error) {
                    setErrorMessage(error instanceof Error ? error.message : 'Failed to open browser');
                    setState('error');
                }
            }
            else {
                // No validation link, just retry
                onChoice('verify');
            }
        }
        else {
            // 'change_auth' or 'cancel'
            onChoice(choice);
        }
    }, [validationLink, onChoice]);
    if (state === 'error') {
        return (_jsxs(Box, { borderStyle: "round", flexDirection: "column", padding: 1, children: [_jsx(Text, { color: theme.status.error, children: errorMessage ||
                        'Failed to open verification link. Please try again or change authentication.' }), _jsx(Box, { marginTop: 1, children: _jsx(RadioButtonSelect, { items: items, onSelect: (choice) => void handleSelect(choice) }) })] }));
    }
    if (state === 'waiting') {
        return (_jsxs(Box, { borderStyle: "round", flexDirection: "column", padding: 1, children: [_jsxs(Box, { children: [_jsx(CliSpinner, {}), _jsxs(Text, { children: [' ', "Waiting for verification... (Press ESC or CTRL+C to cancel)"] })] }), errorMessage && (_jsx(Box, { marginTop: 1, children: _jsx(Text, { children: errorMessage }) })), _jsx(Box, { marginTop: 1, children: _jsx(Text, { dimColor: true, children: "Press Enter when verification is complete." }) })] }));
    }
    if (state === 'complete') {
        return (_jsx(Box, { borderStyle: "round", flexDirection: "column", padding: 1, children: _jsx(Text, { color: theme.status.success, children: "Verification complete" }) }));
    }
    return (_jsxs(Box, { borderStyle: "round", flexDirection: "column", padding: 1, children: [_jsx(Box, { marginBottom: 1, children: _jsx(Text, { children: "Further action is required to use this service." }) }), _jsx(Box, { marginTop: 1, marginBottom: 1, children: _jsx(RadioButtonSelect, { items: items, onSelect: (choice) => void handleSelect(choice) }) }), learnMoreUrl && (_jsx(Box, { marginTop: 1, children: _jsxs(Text, { dimColor: true, children: ["Learn more: ", _jsx(Text, { color: theme.text.accent, children: learnMoreUrl })] }) }))] }));
}
//# sourceMappingURL=ValidationDialog.js.map