//
//  Presentation.swift
//  Presentation
//
//  Created by 강대훈 on 1/16/26.
//

import UIKit

final public class MainViewController: UIViewController {

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        view.backgroundColor = .white
        print("Main")
    }
}
