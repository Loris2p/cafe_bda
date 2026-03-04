import { jsxs as _jsxs, jsx as _jsx, Fragment as _Fragment } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { theme } from '../semantic-colors.js';
import { formatResetTime } from '../utils/formatters.js';
import { getStatusColor, QUOTA_THRESHOLD_HIGH, QUOTA_THRESHOLD_MEDIUM, } from '../utils/displayUtils.js';
export const QuotaStatsInfo = ({ remaining, limit, resetTime, showDetails = true, }) => {
    if (remaining === undefined || limit === undefined || limit === 0) {
        return null;
    }
    const percentage = (remaining / limit) * 100;
    const color = getStatusColor(percentage, {
        green: QUOTA_THRESHOLD_HIGH,
        yellow: QUOTA_THRESHOLD_MEDIUM,
    });
    return (_jsxs(Box, { flexDirection: "column", marginTop: 0, marginBottom: 0, children: [_jsxs(Text, { color: color, children: [remaining === 0
                        ? `Limit reached`
                        : `${percentage.toFixed(0)}% usage remaining`, resetTime && `, ${formatResetTime(resetTime)}`] }), showDetails && (_jsxs(_Fragment, { children: [_jsxs(Text, { color: theme.text.primary, children: ["Usage limit: ", limit.toLocaleString()] }), _jsx(Text, { color: theme.text.primary, children: "Usage limits span all sessions and reset daily." }), remaining === 0 && (_jsx(Text, { color: theme.text.primary, children: "Please /auth to upgrade or switch to an API key to continue." }))] }))] }));
};
//# sourceMappingURL=QuotaStatsInfo.js.map