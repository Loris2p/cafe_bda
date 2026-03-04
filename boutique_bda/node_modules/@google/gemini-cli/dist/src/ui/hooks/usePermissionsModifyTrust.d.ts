/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { TrustLevel } from '../../config/trustedFolders.js';
import { type UseHistoryManagerReturn } from './useHistoryManager.js';
export declare const usePermissionsModifyTrust: (onExit: () => void, addItem: UseHistoryManagerReturn["addItem"], targetDirectory: string) => {
    cwd: string;
    currentTrustLevel: TrustLevel | undefined;
    isInheritedTrustFromParent: boolean;
    isInheritedTrustFromIde: boolean;
    needsRestart: boolean;
    updateTrustLevel: (trustLevel: TrustLevel) => Promise<void>;
    commitTrustLevelChange: () => Promise<boolean>;
    isFolderTrustEnabled: boolean;
};
