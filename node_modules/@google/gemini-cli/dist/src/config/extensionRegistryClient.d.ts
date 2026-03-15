/**
 * @license
 * Copyright 2026 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
export interface RegistryExtension {
    id: string;
    rank: number;
    url: string;
    fullName: string;
    repoDescription: string;
    stars: number;
    lastUpdated: string;
    extensionName: string;
    extensionVersion: string;
    extensionDescription: string;
    avatarUrl: string;
    hasMCP: boolean;
    hasContext: boolean;
    hasHooks: boolean;
    hasSkills: boolean;
    hasCustomCommands: boolean;
    isGoogleOwned: boolean;
    licenseKey: string;
}
export declare class ExtensionRegistryClient {
    private static readonly REGISTRY_URL;
    private static readonly FETCH_TIMEOUT_MS;
    private static fetchPromise;
    /** @internal */
    static resetCache(): void;
    getExtensions(page?: number, limit?: number, orderBy?: 'ranking' | 'alphabetical'): Promise<{
        extensions: RegistryExtension[];
        total: number;
    }>;
    searchExtensions(query: string): Promise<RegistryExtension[]>;
    getExtension(id: string): Promise<RegistryExtension | undefined>;
    private fetchAllExtensions;
}
