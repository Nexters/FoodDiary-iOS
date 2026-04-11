//
//  ViewTransitionHandling.swift
//  Presentation
//

import UIKit

public protocol ViewTransitionHandling: AnyObject {
    func transition(from parent: UIViewController, to viewController: UIViewController)
}
