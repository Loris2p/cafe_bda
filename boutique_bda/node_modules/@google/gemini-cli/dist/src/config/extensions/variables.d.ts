/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import { type VariableSchema } from './variableSchema.js';
export declare const EXTENSIONS_DIRECTORY_NAME: string;
export declare const EXTENSIONS_CONFIG_FILENAME = "gemini-extension.json";
export declare const INSTALL_METADATA_FILENAME = ".gemini-extension-install.json";
export declare const EXTENSION_SETTINGS_FILENAME = ".env";
export type JsonObject = {
    [key: string]: JsonValue;
};
export type JsonArray = JsonValue[];
export type JsonValue = string | number | boolean | null | JsonObject | JsonArray;
export type VariableContext = {
    [key: string]: string | undefined;
};
export declare function validateVariables(variables: VariableContext, schema: VariableSchema): void;
export declare function hydrateString(str: string, context: VariableContext): string;
export declare function recursivelyHydrateStrings<T>(obj: T, values: VariableContext): T;
