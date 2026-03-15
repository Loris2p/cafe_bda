import { jsx as _jsx } from "react/jsx-runtime";
import {} from '@google/gemini-cli-core';
import { useUIState } from '../../contexts/UIStateContext.js';
import { useMemo } from 'react';
import { Checklist } from '../Checklist.js';
export const TodoTray = () => {
    const uiState = useUIState();
    const todos = useMemo(() => {
        // Find the most recent todo list written by the WriteTodosTool
        for (let i = uiState.history.length - 1; i >= 0; i--) {
            const entry = uiState.history[i];
            if (entry.type !== 'tool_group') {
                continue;
            }
            const toolGroup = entry;
            for (const tool of toolGroup.tools) {
                if (typeof tool.resultDisplay !== 'object' ||
                    !('todos' in tool.resultDisplay)) {
                    continue;
                }
                return tool.resultDisplay;
            }
        }
        return null;
    }, [uiState.history]);
    const checklistItems = useMemo(() => {
        if (!todos || !todos.todos) {
            return [];
        }
        return todos.todos.map((todo) => ({
            status: todo.status,
            label: todo.description,
        }));
    }, [todos]);
    if (!todos || !todos.todos) {
        return null;
    }
    return (_jsx(Checklist, { title: "Todo", items: checklistItems, isExpanded: uiState.showFullTodos, toggleHint: "ctrl+t to toggle" }));
};
//# sourceMappingURL=Todo.js.map