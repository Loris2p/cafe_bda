/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import type { CommandModule } from 'yargs';
interface Args {
    name: string;
    session?: boolean;
}
export declare const enableCommand: CommandModule<object, Args>;
export declare const disableCommand: CommandModule<object, Args>;
export {};
