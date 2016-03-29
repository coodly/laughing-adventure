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

private extension Selector {
    static let closeModalPressed = #selector(UIViewController.closeModal)
}

public extension UIViewController {
    public func pushMaybeModally(controller: UIViewController, closeButtonTitle: String = NSLocalizedString("modally.presented.close.button.title", comment: "")) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            navigationController!.pushViewController(controller, animated: true)
        } else {
            let navigation = UINavigationController(rootViewController: controller)
            if let _ = controller.navigationItem.leftBarButtonItem {
                Logging.log("Close button will not be added")
            } else {
                controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: closeButtonTitle, style: .Plain, target: self, action: .closeModalPressed)
            }
            navigation.modalPresentationStyle = .FormSheet
            navigation.modalTransitionStyle = .CrossDissolve
            presentViewController(navigation, animated: true, completion: nil)
        }
    }
    
    public func popOrDismiss() {
        if navigationController!.viewControllers.count == 1 {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController!.popViewControllerAnimated(true)
        }
    }
    
    @objc private func closeModal() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

public protocol QuickAlertPresenter {
    func presentAlert(title: String, message: String, dismissButtonTitle: String)
    func presentErrorAlert(title: String, error: NSError, dismissButtonTitle: String)
}

public extension QuickAlertPresenter where Self: UIViewController {
    func presentAlert(title: String, message: String, dismissButtonTitle: String = NSLocalizedString("generic.button.title.ok", comment: "")) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: dismissButtonTitle, style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentErrorAlert(title: String, error: NSError, dismissButtonTitle: String = NSLocalizedString("generic.button.title.ok", comment: "")) {
        presentAlert(title, message: error.localizedDescription, dismissButtonTitle: dismissButtonTitle)
    }
}
