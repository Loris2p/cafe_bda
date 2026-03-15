/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { CommandModule } from 'yargs';
interface LinkArgs {
    path: string;
    scope?: 'user' | 'workspace';
    consent?: boolean;
}
export declare function handleLink(args: LinkArgs): Promise<void>;
export declare const linkCommand: CommandModule;
export {};
