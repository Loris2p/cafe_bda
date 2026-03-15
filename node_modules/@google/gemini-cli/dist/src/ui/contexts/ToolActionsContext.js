import { jsx as _jsx } from "react/jsx-runtime";
import { createContext, useContext, useCallback, useState, useEffect, } from 'react';
import { IdeClient, ToolConfirmationOutcome, MessageBusType, debugLogger, } from '@google/gemini-cli-core';
function hasLegacyCallback(details) {
    return (!!details &&
        'onConfirm' in details &&
        typeof details.onConfirm === 'function');
}
const ToolActionsContext = createContext(null);
export const useToolActions = () => {
    const context = useContext(ToolActionsContext);
    if (!context) {
        throw new Error('useToolActions must be used within a ToolActionsProvider');
    }
    return context;
};
export const ToolActionsProvider = (props) => {
    const { children, config, toolCalls } = props;
    // Hoist IdeClient logic here to keep UI pure
    const [ideClient, setIdeClient] = useState(null);
    const [isDiffingEnabled, setIsDiffingEnabled] = useState(false);
    useEffect(() => {
        let isMounted = true;
        if (config.getIdeMode()) {
            IdeClient.getInstance()
                .then((client) => {
                if (!isMounted)
                    return;
                setIdeClient(client);
                setIsDiffingEnabled(client.isDiffingEnabled());
                const handleStatusChange = () => {
                    if (isMounted) {
                        setIsDiffingEnabled(client.isDiffingEnabled());
                    }
                };
                client.addStatusChangeListener(handleStatusChange);
                // Return a cleanup function for the listener
                return () => {
                    client.removeStatusChangeListener(handleStatusChange);
                };
            })
                .catch((error) => {
                debugLogger.error('Failed to get IdeClient instance:', error);
            });
        }
        return () => {
            isMounted = false;
        };
    }, [config]);
    const confirm = useCallback(async (callId, outcome, payload) => {
        const tool = toolCalls.find((t) => t.callId === callId);
        if (!tool) {
            debugLogger.warn(`ToolActions: Tool ${callId} not found`);
            return;
        }
        const details = tool.confirmationDetails;
        // 1. Handle Side Effects (IDE Diff)
        if (details?.type === 'edit' &&
            isDiffingEnabled &&
            'filePath' in details // Check for safety
        ) {
            const cliOutcome = outcome === ToolConfirmationOutcome.Cancel ? 'rejected' : 'accepted';
            await ideClient?.resolveDiffFromCli(details.filePath, cliOutcome);
        }
        // 2. Dispatch via Event Bus
        if (tool.correlationId) {
            await config.getMessageBus().publish({
                type: MessageBusType.TOOL_CONFIRMATION_RESPONSE,
                correlationId: tool.correlationId,
                confirmed: outcome !== ToolConfirmationOutcome.Cancel,
                requiresUserConfirmation: false,
                outcome,
                payload,
            });
            return;
        }
        // 3. Fallback: Legacy Callback
        if (hasLegacyCallback(details)) {
            await details.onConfirm(outcome, payload);
            return;
        }
        debugLogger.warn(`ToolActions: No correlationId or callback for ${callId}`);
    }, [config, ideClient, toolCalls, isDiffingEnabled]);
    const cancel = useCallback(async (callId) => {
        await confirm(callId, ToolConfirmationOutcome.Cancel);
    }, [confirm]);
    return (_jsx(ToolActionsContext.Provider, { value: { confirm, cancel, isDiffingEnabled }, children: children }));
};
//# sourceMappingURL=ToolActionsContext.js.map