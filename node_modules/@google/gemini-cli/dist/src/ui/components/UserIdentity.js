import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import { useMemo } from 'react';
import { Box, Text } from 'ink';
import { theme } from '../semantic-colors.js';
import { UserAccountManager, AuthType, } from '@google/gemini-cli-core';
export const UserIdentity = ({ config }) => {
    const authType = config.getContentGeneratorConfig()?.authType;
    const { email, tierName } = useMemo(() => {
        if (!authType) {
            return { email: undefined, tierName: undefined };
        }
        const userAccountManager = new UserAccountManager();
        return {
            email: userAccountManager.getCachedGoogleAccount(),
            tierName: config.getUserTierName(),
        };
    }, [config, authType]);
    if (!authType) {
        return null;
    }
    return (_jsxs(Box, { marginTop: 1, flexDirection: "column", children: [_jsxs(Box, { children: [_jsx(Text, { color: theme.text.primary, children: authType === AuthType.LOGIN_WITH_GOOGLE ? (_jsxs(Text, { children: [_jsxs(Text, { bold: true, children: ["Logged in with Google", email ? ':' : ''] }), email ? ` ${email}` : ''] })) : (`Authenticated with ${authType}`) }), _jsx(Text, { color: theme.text.secondary, children: " /auth" })] }), tierName && (_jsxs(Text, { color: theme.text.primary, children: [_jsx(Text, { bold: true, children: "Plan:" }), " ", tierName] }))] }));
};
//# sourceMappingURL=UserIdentity.js.map