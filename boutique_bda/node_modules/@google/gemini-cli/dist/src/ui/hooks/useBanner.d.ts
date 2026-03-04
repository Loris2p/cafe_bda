/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */
interface BannerData {
    defaultText: string;
    warningText: string;
}
export declare function useBanner(bannerData: BannerData): {
    bannerText: string;
};
export {};
