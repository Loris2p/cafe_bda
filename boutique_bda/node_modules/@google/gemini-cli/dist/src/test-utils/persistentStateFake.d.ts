/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * A fake implementation of PersistentState for testing.
 * It keeps state in memory and provides spies for get and set.
 */
export declare class FakePersistentState {
    private data;
    get: import("vitest").Mock<(...args: any[]) => any>;
    set: import("vitest").Mock<(...args: any[]) => any>;
    /**
     * Helper to reset the fake state between tests.
     */
    reset(): void;
    /**
     * Helper to clear mock call history without wiping data.
     */
    mockClear(): void;
    /**
     * Helper to set initial data for the fake.
     */
    setData(data: Record<string, unknown>): void;
}
