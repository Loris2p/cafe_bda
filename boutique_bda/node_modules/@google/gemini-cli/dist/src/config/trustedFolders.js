/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as crypto from 'node:crypto';
import { lock } from 'proper-lockfile';
import { FatalConfigError, getErrorMessage, isWithinRoot, ideContextStore, GEMINI_DIR, homedir, isHeadlessMode, coreEvents, } from '@google/gemini-cli-core';
import stripJsonComments from 'strip-json-comments';
const { promises: fsPromises } = fs;
export const TRUSTED_FOLDERS_FILENAME = 'trustedFolders.json';
export function getUserSettingsDir() {
    return path.join(homedir(), GEMINI_DIR);
}
export function getTrustedFoldersPath() {
    if (process.env['GEMINI_CLI_TRUSTED_FOLDERS_PATH']) {
        return process.env['GEMINI_CLI_TRUSTED_FOLDERS_PATH'];
    }
    return path.join(getUserSettingsDir(), TRUSTED_FOLDERS_FILENAME);
}
export var TrustLevel;
(function (TrustLevel) {
    TrustLevel["TRUST_FOLDER"] = "TRUST_FOLDER";
    TrustLevel["TRUST_PARENT"] = "TRUST_PARENT";
    TrustLevel["DO_NOT_TRUST"] = "DO_NOT_TRUST";
})(TrustLevel || (TrustLevel = {}));
export function isTrustLevel(value) {
    return (typeof value === 'string' &&
        // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
        Object.values(TrustLevel).includes(value));
}
const realPathCache = new Map();
/**
 * Parses the trusted folders JSON content, stripping comments.
 */
function parseTrustedFoldersJson(content) {
    return JSON.parse(stripJsonComments(content));
}
/**
 * FOR TESTING PURPOSES ONLY.
 * Clears the real path cache.
 */
export function clearRealPathCacheForTesting() {
    realPathCache.clear();
}
function getRealPath(location) {
    let realPath = realPathCache.get(location);
    if (realPath !== undefined) {
        return realPath;
    }
    try {
        realPath = fs.existsSync(location) ? fs.realpathSync(location) : location;
    }
    catch {
        realPath = location;
    }
    realPathCache.set(location, realPath);
    return realPath;
}
export class LoadedTrustedFolders {
    user;
    errors;
    constructor(user, errors) {
        this.user = user;
        this.errors = errors;
    }
    get rules() {
        return Object.entries(this.user.config).map(([path, trustLevel]) => ({
            path,
            trustLevel,
        }));
    }
    /**
     * Returns true or false if the path should be "trusted". This function
     * should only be invoked when the folder trust setting is active.
     *
     * @param location path
     * @returns
     */
    isPathTrusted(location, config, headlessOptions) {
        if (isHeadlessMode(headlessOptions)) {
            return true;
        }
        const configToUse = config ?? this.user.config;
        // Resolve location to its realpath for canonical comparison
        const realLocation = getRealPath(location);
        let longestMatchLen = -1;
        let longestMatchTrust = undefined;
        for (const [rulePath, trustLevel] of Object.entries(configToUse)) {
            const effectivePath = trustLevel === TrustLevel.TRUST_PARENT
                ? path.dirname(rulePath)
                : rulePath;
            // Resolve effectivePath to its realpath for canonical comparison
            const realEffectivePath = getRealPath(effectivePath);
            if (isWithinRoot(realLocation, realEffectivePath)) {
                if (rulePath.length > longestMatchLen) {
                    longestMatchLen = rulePath.length;
                    longestMatchTrust = trustLevel;
                }
            }
        }
        if (longestMatchTrust === TrustLevel.DO_NOT_TRUST)
            return false;
        if (longestMatchTrust === TrustLevel.TRUST_FOLDER ||
            longestMatchTrust === TrustLevel.TRUST_PARENT)
            return true;
        return undefined;
    }
    async setValue(folderPath, trustLevel) {
        if (this.errors.length > 0) {
            const errorMessages = this.errors.map((error) => `Error in ${error.path}: ${error.message}`);
            throw new FatalConfigError(`Cannot update trusted folders because the configuration file is invalid:\n${errorMessages.join('\n')}\nPlease fix the file manually before trying to update it.`);
        }
        const dirPath = path.dirname(this.user.path);
        if (!fs.existsSync(dirPath)) {
            await fsPromises.mkdir(dirPath, { recursive: true });
        }
        // lockfile requires the file to exist
        if (!fs.existsSync(this.user.path)) {
            await fsPromises.writeFile(this.user.path, JSON.stringify({}, null, 2), {
                mode: 0o600,
            });
        }
        const release = await lock(this.user.path, {
            retries: {
                retries: 10,
                minTimeout: 100,
            },
        });
        try {
            // Re-read the file to handle concurrent updates
            const content = await fsPromises.readFile(this.user.path, 'utf-8');
            let config;
            try {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
                config = parseTrustedFoldersJson(content);
            }
            catch (error) {
                coreEvents.emitFeedback('error', `Failed to parse trusted folders file at ${this.user.path}. The file may be corrupted.`, error);
                config = {};
            }
            const originalTrustLevel = config[folderPath];
            config[folderPath] = trustLevel;
            this.user.config[folderPath] = trustLevel;
            try {
                saveTrustedFolders({ ...this.user, config });
            }
            catch (e) {
                // Revert the in-memory change if the save failed.
                if (originalTrustLevel === undefined) {
                    delete this.user.config[folderPath];
                }
                else {
                    this.user.config[folderPath] = originalTrustLevel;
                }
                throw e;
            }
        }
        finally {
            await release();
        }
    }
}
let loadedTrustedFolders;
/**
 * FOR TESTING PURPOSES ONLY.
 * Resets the in-memory cache of the trusted folders configuration.
 */
export function resetTrustedFoldersForTesting() {
    loadedTrustedFolders = undefined;
    clearRealPathCacheForTesting();
}
export function loadTrustedFolders() {
    if (loadedTrustedFolders) {
        return loadedTrustedFolders;
    }
    const errors = [];
    const userConfig = {};
    const userPath = getTrustedFoldersPath();
    try {
        if (fs.existsSync(userPath)) {
            const content = fs.readFileSync(userPath, 'utf-8');
            // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
            const parsed = parseTrustedFoldersJson(content);
            if (typeof parsed !== 'object' ||
                parsed === null ||
                Array.isArray(parsed)) {
                errors.push({
                    message: 'Trusted folders file is not a valid JSON object.',
                    path: userPath,
                });
            }
            else {
                for (const [path, trustLevel] of Object.entries(parsed)) {
                    if (isTrustLevel(trustLevel)) {
                        userConfig[path] = trustLevel;
                    }
                    else {
                        const possibleValues = Object.values(TrustLevel).join(', ');
                        errors.push({
                            message: `Invalid trust level "${trustLevel}" for path "${path}". Possible values are: ${possibleValues}.`,
                            path: userPath,
                        });
                    }
                }
            }
        }
    }
    catch (error) {
        errors.push({
            message: getErrorMessage(error),
            path: userPath,
        });
    }
    loadedTrustedFolders = new LoadedTrustedFolders({ path: userPath, config: userConfig }, errors);
    return loadedTrustedFolders;
}
export function saveTrustedFolders(trustedFoldersFile) {
    // Ensure the directory exists
    const dirPath = path.dirname(trustedFoldersFile.path);
    if (!fs.existsSync(dirPath)) {
        fs.mkdirSync(dirPath, { recursive: true });
    }
    const content = JSON.stringify(trustedFoldersFile.config, null, 2);
    const tempPath = `${trustedFoldersFile.path}.tmp.${crypto.randomUUID()}`;
    try {
        fs.writeFileSync(tempPath, content, {
            encoding: 'utf-8',
            mode: 0o600,
        });
        fs.renameSync(tempPath, trustedFoldersFile.path);
    }
    catch (error) {
        // Clean up temp file if it was created but rename failed
        if (fs.existsSync(tempPath)) {
            try {
                fs.unlinkSync(tempPath);
            }
            catch {
                // Ignore cleanup errors
            }
        }
        throw error;
    }
}
/** Is folder trust feature enabled per the current applied settings */
export function isFolderTrustEnabled(settings) {
    const folderTrustSetting = settings.security?.folderTrust?.enabled ?? true;
    return folderTrustSetting;
}
function getWorkspaceTrustFromLocalConfig(workspaceDir, trustConfig, headlessOptions) {
    const folders = loadTrustedFolders();
    const configToUse = trustConfig ?? folders.user.config;
    if (folders.errors.length > 0) {
        const errorMessages = folders.errors.map((error) => `Error in ${error.path}: ${error.message}`);
        throw new FatalConfigError(`${errorMessages.join('\n')}\nPlease fix the configuration file and try again.`);
    }
    const isTrusted = folders.isPathTrusted(workspaceDir, configToUse, headlessOptions);
    return {
        isTrusted,
        source: isTrusted !== undefined ? 'file' : undefined,
    };
}
export function isWorkspaceTrusted(settings, workspaceDir = process.cwd(), trustConfig, headlessOptions) {
    if (isHeadlessMode(headlessOptions)) {
        return { isTrusted: true, source: undefined };
    }
    if (!isFolderTrustEnabled(settings)) {
        return { isTrusted: true, source: undefined };
    }
    const ideTrust = ideContextStore.get()?.workspaceState?.isTrusted;
    if (ideTrust !== undefined) {
        return { isTrusted: ideTrust, source: 'ide' };
    }
    // Fall back to the local user configuration
    return getWorkspaceTrustFromLocalConfig(workspaceDir, trustConfig, headlessOptions);
}
//# sourceMappingURL=trustedFolders.js.map