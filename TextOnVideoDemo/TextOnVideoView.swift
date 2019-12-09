//
//  TextOnVideoView.swift
//  TextOnVideoDemo
//
//  Created by Jonathan Yee on 12/8/19.
//  Copyright © 2019 Jonathan Yee. All rights reserved.
//

import UIKit

class TextOnVideoView: UIView {

    let activityIndicator = UIActivityIndicatorView(style: .large)
    let chooseVideoButton = UIButton(type: .roundedRect)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        chooseVideoButton.translatesAutoresizingMaskIntoConstraints = false
        chooseVideoButton.setTitle("Select Video", for: .normal)

        self.addSubview(chooseVideoButton)

        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.color = UIColor.black
        self.activityIndicator.hidesWhenStopped = true

        self.addSubview(self.activityIndicator)

        NSLayoutConstraint.activate([
            chooseVideoButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
            chooseVideoButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
            self.activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
