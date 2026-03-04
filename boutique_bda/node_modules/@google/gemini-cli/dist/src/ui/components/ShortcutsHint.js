import { jsx as _jsx } from "react/jsx-runtime";
import { Text } from 'ink';
import { theme } from '../semantic-colors.js';
import { useUIState } from '../contexts/UIStateContext.js';
export const ShortcutsHint = () => {
    const { cleanUiDetailsVisible, shortcutsHelpVisible } = useUIState();
    if (!cleanUiDetailsVisible) {
        return _jsx(Text, { color: theme.text.secondary, children: " press tab twice for more " });
    }
    const highlightColor = shortcutsHelpVisible
        ? theme.text.accent
        : theme.text.secondary;
    return _jsx(Text, { color: highlightColor, children: " ? for shortcuts " });
};
//# sourceMappingURL=ShortcutsHint.js.map