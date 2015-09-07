/*
* Copyright 2015 Coodly LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import iAd

public class AppleAdPresentingContainerViewController: AdPresentingContainerViewController, ADBannerViewDelegate {
    public override func createBanner() -> UIView {
        let adBanner = ADBannerView(adType: ADAdType.Banner)
        adBanner.delegate = self
        
        return adBanner
    }
    
    public func bannerViewDidLoadAd(banner: ADBannerView!) {
        showBanner(banner)
    }
    
    public func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        hideBanner(banner)
    }
}
