//
//  MainViewController.swift
//  Main
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit
import SnapKit

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



