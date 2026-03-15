/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type AgentDefinition } from '@google/gemini-cli-core';
export declare enum NewAgentsChoice {
    ACKNOWLEDGE = "acknowledge",
    IGNORE = "ignore"
}
interface NewAgentsNotificationProps {
    agents: AgentDefinition[];
    onSelect: (choice: NewAgentsChoice) => void | Promise<void>;
}
export declare const NewAgentsNotification: ({ agents, onSelect, }: NewAgentsNotificationProps) => import("react/jsx-runtime").JSX.Element;
export {};
