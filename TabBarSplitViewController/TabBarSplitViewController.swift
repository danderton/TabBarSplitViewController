//
//  TabBarSplitViewController.swift
//  iNDIEPASS
//
//  Created by Denken on 6/29/15.
//  Copyright (c) 2015 iNDIEVOX. All rights reserved.
//

// This class handles everything about UISplitViewController and corresponding size class collapsing/expanding.

import UIKit

// MARK: PrimaryViewController

extension PrimaryViewControllerProtocol {

    static func _viewControllersToExpand(from primaryNavViewController: UINavigationController) -> [UIViewController]? {
        var vcsToExpand = [UIViewController]()
        for viewController in primaryNavViewController.viewControllers {
            vcsToExpand.append(viewController)
        }
        return vcsToExpand
    }
}

extension UITabBarController : PrimaryViewControllerProtocol {

    func viewControllersToExpand() -> [UIViewController]? {
        if let primaryNavViewController = selectedViewController as? UINavigationController {
            return UITabBarController._viewControllersToExpand(from: primaryNavViewController)
        }
        return nil
    }

    func collapsedToPrimaryViewController() -> UINavigationController? {
        if let primaryNavViewController = selectedViewController as? UINavigationController {
            return primaryNavViewController
        }
        return nil
    }
}

extension UINavigationController : PrimaryViewControllerProtocol {

    func viewControllersToExpand() -> [UIViewController]? {
        return UINavigationController._viewControllersToExpand(from: self)
    }

    func collapsedToPrimaryViewController() -> UINavigationController? {
        return self
    }
}

// MARK: SecondaryViewController

extension UIViewController : SecondaryViewControllerProtocol {

    func viewControllersToCollapse() -> [UIViewController]? {
        if let navigationController = self as? UINavigationController {
            return navigationController.viewControllers
        }
        return [self]
    }

    static func secondaryViewControllerToExpand(viewControllers: [UIViewController]) -> UIViewController? {
        if self === UINavigationController.self {
            let navigationController = UINavigationController()
            navigationController.setViewControllers(viewControllers, animated: false)
            return navigationController
        } else {
            if viewControllers.count > 1 {
                assertionFailure("Expanding multiple viewControllers not supported; showDetailViewController for more than once?")
            }
            if let viewController = viewControllers.last {
                return viewController
            }
        }
        return nil
    }
}

// MARK: TabBarSplitViewController Public Init

extension TabBarSplitViewController {

    /**
     TabBarSplitViewController

     - Parameter primaryViewControllers: View controllers for UITabBarController as primary; if setting only 1 view controller, will fall back to UINavigationController as primary.
     - Parameter SecondaryViewControllerConfiguration:
         - General: class that can be expanded in regular horizontalSizeClass
         - withNav: with UINavigationController as secondary
         - Empty: class to be presented when no detail available
     */
    public convenience init(primaryViewControllers: [UINavigationController], SecondaryViewControllerConfiguration secondary: (General: UIViewController.Type, withNav: Bool, Empty: UIViewController.Type)) {

        switch primaryViewControllers.count {
        case 1:
            let navigationController = primaryViewControllers.first!
            switch secondary.withNav {
            case true:
                self.init(primaryViewController: navigationController, SecondaryViewControllerType: UINavigationController.self,
                    SecondaryInsideViewControllerTypes: (General: secondary.General, Empty: secondary.Empty))
            case false:
                self.init(primaryViewController: navigationController, SecondaryViewControllerType: secondary.General,
                    SecondaryInsideViewControllerTypes: (General: secondary.General, Empty: secondary.Empty))
            }
        default:
            let tabBarController = UITabBarController()
            tabBarController.viewControllers = primaryViewControllers
            switch secondary.withNav {
            case true:
                self.init(primaryViewController: tabBarController, SecondaryViewControllerType: UINavigationController.self,
                    SecondaryInsideViewControllerTypes: (General: secondary.General, Empty: secondary.Empty))
            case false:
                self.init(primaryViewController: tabBarController, SecondaryViewControllerType: secondary.General,
                    SecondaryInsideViewControllerTypes: (General: secondary.General, Empty: secondary.Empty))
            }
        }
    }

    /**
    TabBarSplitViewController (Bridging for Objective-C)

    - Parameter primaryViewControllers: View controllers for UITabBarController as primary; if setting only 1 view controller, will fall back to UINavigationController as primary.
    - Parameter detailClassGeneral: class that can be expanded in regular horizontalSizeClass
    - Parameter withNavigationController: with UINavigationController as secondary
    - Parameter detailClassEmpty: class to be presented when no detail available
    */
    public convenience init(primaryViewControllers: [UINavigationController], detailClassGeneral: UIViewController.Type, withNavigationController: Bool, detailClassEmpty: UIViewController.Type) {
        self.init(primaryViewControllers: primaryViewControllers, SecondaryViewControllerConfiguration: (detailClassGeneral, withNavigationController, detailClassEmpty))
    }
}

// MARK: -

// MARK: TabBarSplitViewController Protocols

protocol PrimaryViewControllerProtocol {
    /// Just return all view controllers; SecondaryInsideViewControllerTypes.General will be checked later and only those be expanded.
    func viewControllersToExpand() -> [UIViewController]?
    func collapsedToPrimaryViewController() -> UINavigationController?
}

protocol SecondaryViewControllerProtocol {
    func viewControllersToCollapse() -> [UIViewController]?
    /// SecondaryViewController factory method
    static func secondaryViewControllerToExpand(viewControllers: [UIViewController]) -> UIViewController?
}

// MARK: TabBarSplitViewController

@available(iOS 8.0, *)
public class TabBarSplitViewController: UISplitViewController {

    let SecondaryViewControllerType : SecondaryViewControllerProtocol.Type
    let SecondaryInsideViewControllerTypes : (General: UIViewController.Type, Empty: UIViewController.Type)

    init(primaryViewController: PrimaryViewControllerProtocol, SecondaryViewControllerType: SecondaryViewControllerProtocol.Type, SecondaryInsideViewControllerTypes: (General: UIViewController.Type, Empty: UIViewController.Type)) {
        self.SecondaryViewControllerType = SecondaryViewControllerType
        self.SecondaryInsideViewControllerTypes = SecondaryInsideViewControllerTypes
        super.init(nibName: nil, bundle: nil)

        if let primaryViewController = primaryViewController as? UITabBarController {
            let secondaryViewController = SecondaryInsideViewControllerTypes.Empty.init()
            viewControllers = [primaryViewController, secondaryViewController]
        } else if let primaryViewController = primaryViewController as? UINavigationController {
            let secondaryViewController = SecondaryInsideViewControllerTypes.Empty.init()
            viewControllers = [primaryViewController, secondaryViewController]
        }

        preferredDisplayMode = .AllVisible
        delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: UISplitViewControllerDelegate
extension TabBarSplitViewController: UISplitViewControllerDelegate {

    // MARK: to Compact Width size class (collapse)
    public func primaryViewControllerForCollapsingSplitViewController(splitViewController: UISplitViewController) -> UIViewController? {
        if let primaryViewController = splitViewController.viewControllers[0] as? PrimaryViewControllerProtocol,
            primaryInsideViewController = primaryViewController.collapsedToPrimaryViewController() {
                let secondaryViewController = splitViewController.viewControllers[1]
                if let viewControllersToCollapse = secondaryViewController.viewControllersToCollapse() {
                    var vcsToCollapse = [UIViewController]()
                    for viewControllerToCollapse in viewControllersToCollapse {
                        if (viewControllerToCollapse.dynamicType === SecondaryInsideViewControllerTypes.Empty) {
                            break
                        }
                        vcsToCollapse.append(viewControllerToCollapse)
                    }
                    var viewControllers = primaryInsideViewController.viewControllers
                    if viewControllers.last === vcsToCollapse.first {
                        viewControllers.removeLast()
                    }
                    viewControllers += vcsToCollapse
                    dispatch_async(dispatch_get_main_queue()) {     // otherwise we may get console error "<Error>: CGImageCreate: invalid image size: 0 x 0."
                        primaryInsideViewController.setViewControllers(viewControllers, animated: false)
                    }
                    if let primaryViewController = primaryViewController as? UIViewController {
                        return primaryViewController
                    }
                }
        }
        return nil
    }

    public func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return true
    }

    // MARK: to Regular Width size class (separate/expand)

    public func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if let primaryViewController = splitViewController.viewControllers[0] as? PrimaryViewControllerProtocol,
         primaryInsideViewController = primaryViewController.collapsedToPrimaryViewController(),
            viewControllersToExpand = primaryViewController.viewControllersToExpand() {
                var vcsToExpand = [UIViewController]()
                for viewControllerToExpand in viewControllersToExpand.reverse() {   // reverse: check from top view controller
                    if viewControllerToExpand.dynamicType === SecondaryInsideViewControllerTypes.General {
                        primaryInsideViewController.popViewControllerAnimated(false)
                        vcsToExpand.append(viewControllerToExpand)
                    } else {
                        break
                    }
                }
                if vcsToExpand.count > 0 {
                    let secondaryViewController = SecondaryViewControllerType.secondaryViewControllerToExpand(vcsToExpand.reverse()) // reverse: show from bottom to top view controller
                    return secondaryViewController
                }
        }

        return SecondaryInsideViewControllerTypes.Empty.init()
    }

    public func primaryViewControllerForExpandingSplitViewController(splitViewController: UISplitViewController) -> UIViewController? {
        return nil
    }

    // MARK: override showDetailViewController
    public func splitViewController(splitViewController: UISplitViewController, showDetailViewController vc: UIViewController, sender: AnyObject?) -> Bool {
        let isCompactWidth = (splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact)
        if isCompactWidth {
            if let primaryViewController = splitViewController.viewControllers[0] as? PrimaryViewControllerProtocol,
                primaryInsideViewController = primaryViewController.collapsedToPrimaryViewController() {
                    if let _ = SecondaryViewControllerType as? UINavigationController.Type, vc = vc as? UINavigationController, topViewController = vc.topViewController {
                            primaryInsideViewController.showViewController(topViewController, sender: self)
                    } else {
                        primaryInsideViewController.showViewController(vc, sender: self)
                    }
                    return true
            }
        }

        return false
    }
}