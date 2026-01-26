//
//  MainViewController.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import UIKit

public final class MainViewController: UIViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.text = "메인화면"
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 50),
            label.widthAnchor.constraint(equalToConstant: 50),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
}

