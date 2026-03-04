import { jsx as _jsx } from "react/jsx-runtime";
import { Box } from 'ink';
import { theme } from '../../semantic-colors.js';
export const HorizontalLine = ({ color = theme.border.default, }) => (_jsx(Box, { width: "100%", borderStyle: "single", borderTop: true, borderBottom: false, borderLeft: false, borderRight: false, borderColor: color }));
//# sourceMappingURL=HorizontalLine.js.map