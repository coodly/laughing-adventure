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

import UIKit
import iAd

public class AdPresentingContainerViewController: UIViewController, ADBannerViewDelegate {
    @IBOutlet var adContainerView: UIView!
    @IBOutlet var adContainerHeightConstraint: NSLayoutConstraint!
    
    var banner: ADBannerView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        adContainerHeightConstraint.constant = 0
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public override func viewDidAppear(animated: Bool) {
        loadAd()
    }
    
    func loadAd() {
        if let banner = self.banner {
            return
        }
        
        let adBanner = ADBannerView(adType: ADAdType.Banner)
        self.banner = adBanner
        adBanner.delegate = self
        adBanner.autoresizingMask = [UIViewAutoresizing.FlexibleLeftMargin, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleBottomMargin]
        adContainerView.addSubview(adBanner)
    }
    
    public func bannerViewDidLoadAd(banner: ADBannerView!) {
        banner.center = CGPointMake(CGRectGetWidth(adContainerView.frame) / 2, CGRectGetHeight(adContainerView.frame) / 2)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.adContainerHeightConstraint.constant = CGRectGetHeight(banner.frame)
            self.view.layoutIfNeeded()
        })
    }
    
    public func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.adContainerHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
}
