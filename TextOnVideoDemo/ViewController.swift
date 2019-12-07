//
//  ViewController.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/7/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }

    private func setup() {
        self.view.backgroundColor = UIColor.white

        let chooseVideoButton = UIButton(type: .roundedRect)
        chooseVideoButton.setTitle("Select Video", for: .normal)
        chooseVideoButton.addTarget(self, action: #selector(startPhotoPicker), for: .touchUpInside)
        chooseVideoButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(chooseVideoButton)

        NSLayoutConstraint.activate([
            chooseVideoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            chooseVideoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15)
        ])
    }

    @objc private func startPhotoPicker() {

    }

}

