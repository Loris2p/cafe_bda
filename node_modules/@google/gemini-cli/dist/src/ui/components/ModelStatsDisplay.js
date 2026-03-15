import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Box, Text } from 'ink';
import { theme } from '../semantic-colors.js';
import { formatDuration } from '../utils/formatters.js';
import { calculateAverageLatency, calculateCacheHitRate, calculateErrorRate, } from '../utils/computeStats.js';
import { useSessionStats, } from '../contexts/SessionContext.js';
import { Table } from './Table.js';
import { useSettings } from '../contexts/SettingsContext.js';
import { getDisplayString, isAutoModel, LlmRole, } from '@google/gemini-cli-core';
import { QuotaStatsInfo } from './QuotaStatsInfo.js';
export const ModelStatsDisplay = ({ selectedAuthType, userEmail, tier, currentModel, quotaStats, }) => {
    const { stats } = useSessionStats();
    const pooledRemaining = quotaStats?.remaining;
    const pooledLimit = quotaStats?.limit;
    const pooledResetTime = quotaStats?.resetTime;
    const { models } = stats.metrics;
    const settings = useSettings();
    const showUserIdentity = settings.merged.ui.showUserIdentity;
    const activeModels = Object.entries(models).filter(([, metrics]) => metrics.api.totalRequests > 0);
    if (activeModels.length === 0) {
        return (_jsx(Box, { borderStyle: "round", borderColor: theme.border.default, paddingTop: 1, paddingX: 2, children: _jsx(Text, { color: theme.text.primary, children: "No API calls have been made in this session." }) }));
    }
    const modelNames = activeModels.map(([name]) => name);
    const hasThoughts = activeModels.some(([, metrics]) => metrics.tokens.thoughts > 0);
    const hasTool = activeModels.some(([, metrics]) => metrics.tokens.tool > 0);
    const hasCached = activeModels.some(([, metrics]) => metrics.tokens.cached > 0);
    const allRoles = [
        ...new Set(activeModels.flatMap(([, metrics]) => Object.keys(metrics.roles ?? {}))),
    ]
        .filter((role) => {
        const validRoles = Object.values(LlmRole);
        return validRoles.includes(role);
    })
        .sort((a, b) => {
        if (a === b)
            return 0;
        if (a === LlmRole.MAIN)
            return -1;
        if (b === LlmRole.MAIN)
            return 1;
        return a.localeCompare(b);
    });
    // Helper to create a row with values for each model
    const createRow = (metric, getValue, options = {}) => {
        const row = {
            metric,
            isSection: options.isSection,
            isSubtle: options.isSubtle,
        };
        activeModels.forEach(([name, metrics]) => {
            row[name] = getValue(metrics);
        });
        return row;
    };
    const rows = [];
    // API Section
    rows.push({ metric: 'API', isSection: true });
    rows.push(createRow('Requests', (m) => m.api.totalRequests.toLocaleString()));
    rows.push(createRow('Errors', (m) => {
        const errorRate = calculateErrorRate(m);
        return (_jsxs(Text, { color: m.api.totalErrors > 0 ? theme.status.error : theme.text.primary, children: [m.api.totalErrors.toLocaleString(), " (", errorRate.toFixed(1), "%)"] }));
    }));
    rows.push(createRow('Avg Latency', (m) => formatDuration(calculateAverageLatency(m))));
    // Spacer
    rows.push({ metric: '' });
    // Tokens Section
    rows.push({ metric: 'Tokens', isSection: true });
    rows.push(createRow('Total', (m) => (_jsx(Text, { color: theme.text.secondary, children: m.tokens.total.toLocaleString() }))));
    rows.push(createRow('Input', (m) => (_jsx(Text, { color: theme.text.primary, children: m.tokens.input.toLocaleString() })), { isSubtle: true }));
    if (hasCached) {
        rows.push(createRow('Cache Reads', (m) => {
            const cacheHitRate = calculateCacheHitRate(m);
            return (_jsxs(Text, { color: theme.text.secondary, children: [m.tokens.cached.toLocaleString(), " (", cacheHitRate.toFixed(1), "%)"] }));
        }, { isSubtle: true }));
    }
    if (hasThoughts) {
        rows.push(createRow('Thoughts', (m) => (_jsx(Text, { color: theme.text.primary, children: m.tokens.thoughts.toLocaleString() })), { isSubtle: true }));
    }
    if (hasTool) {
        rows.push(createRow('Tool', (m) => (_jsx(Text, { color: theme.text.primary, children: m.tokens.tool.toLocaleString() })), { isSubtle: true }));
    }
    rows.push(createRow('Output', (m) => (_jsx(Text, { color: theme.text.primary, children: m.tokens.candidates.toLocaleString() })), { isSubtle: true }));
    // Roles Section
    if (allRoles.length > 0) {
        // Spacer
        rows.push({ metric: '' });
        rows.push({ metric: 'Roles', isSection: true });
        allRoles.forEach((role) => {
            // Role Header Row
            const roleHeaderRow = {
                metric: role,
                isSection: true,
                color: theme.text.primary,
            };
            // We don't populate model values for the role header row
            rows.push(roleHeaderRow);
            const addRoleMetric = (metric, getValue) => {
                const row = {
                    metric,
                    isSubtle: true,
                };
                activeModels.forEach(([name, metrics]) => {
                    const roleMetrics = metrics.roles?.[role];
                    if (roleMetrics) {
                        row[name] = getValue(roleMetrics);
                    }
                    else {
                        row[name] = _jsx(Text, { color: theme.text.secondary, children: "-" });
                    }
                });
                rows.push(row);
            };
            addRoleMetric('Requests', (r) => r.totalRequests.toLocaleString());
            addRoleMetric('Input', (r) => (_jsx(Text, { color: theme.text.primary, children: r.tokens.input.toLocaleString() })));
            addRoleMetric('Output', (r) => (_jsx(Text, { color: theme.text.primary, children: r.tokens.candidates.toLocaleString() })));
            addRoleMetric('Cache Reads', (r) => (_jsx(Text, { color: theme.text.secondary, children: r.tokens.cached.toLocaleString() })));
        });
    }
    const columns = [
        {
            key: 'metric',
            header: 'Metric',
            width: 28,
            renderCell: (row) => (_jsx(Text, { bold: row.isSection, color: row.isSection ? theme.text.primary : theme.text.link, children: row.isSubtle ? `  ↳ ${row.metric}` : row.metric })),
        },
        ...modelNames.map((name) => ({
            key: name,
            header: name,
            flexGrow: 1,
            renderCell: (row) => {
                // Don't render anything for section headers in model columns
                if (row.isSection)
                    return null;
                const val = row[name];
                if (val === undefined || val === null)
                    return null;
                if (typeof val === 'string' || typeof val === 'number') {
                    return _jsx(Text, { color: theme.text.primary, children: val });
                }
                return val;
            },
        })),
    ];
    const isAuto = currentModel && isAutoModel(currentModel);
    const statsTitle = isAuto
        ? `${getDisplayString(currentModel)} Stats For Nerds`
        : 'Model Stats For Nerds';
    return (_jsxs(Box, { borderStyle: "round", borderColor: theme.border.default, flexDirection: "column", paddingTop: 1, paddingX: 2, children: [_jsx(Text, { bold: true, color: theme.text.accent, children: statsTitle }), _jsx(Box, { height: 1 }), showUserIdentity && selectedAuthType && (_jsxs(Box, { children: [_jsx(Box, { width: 28, children: _jsx(Text, { color: theme.text.link, children: "Auth Method:" }) }), _jsx(Text, { color: theme.text.primary, children: selectedAuthType.startsWith('oauth')
                            ? userEmail
                                ? `Logged in with Google (${userEmail})`
                                : 'Logged in with Google'
                            : selectedAuthType })] })), showUserIdentity && tier && (_jsxs(Box, { children: [_jsx(Box, { width: 28, children: _jsx(Text, { color: theme.text.link, children: "Tier:" }) }), _jsx(Text, { color: theme.text.primary, children: tier })] })), isAuto &&
                pooledRemaining !== undefined &&
                pooledLimit !== undefined &&
                pooledLimit > 0 && (_jsx(QuotaStatsInfo, { remaining: pooledRemaining, limit: pooledLimit, resetTime: pooledResetTime })), (showUserIdentity || isAuto) && _jsx(Box, { height: 1 }), _jsx(Table, { data: rows, columns: columns })] }));
};
//# sourceMappingURL=ModelStatsDisplay.js.map