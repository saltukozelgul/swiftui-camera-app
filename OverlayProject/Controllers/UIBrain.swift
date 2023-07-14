//
//  UIBrain.swift
//  OverlayProject
//
//  Created by Saltuk Bugra OZELGUL on 14.07.2023.
//

import Foundation
import UIKit

class UIBrain {
    
    public static func setRecordButtonProperties(_ recordButton: UIButton, _ view: UIView){
        recordButton.setTitle("Record", for: .normal)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.layer.zPosition = 1000
        view.addSubview(recordButton)
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    public static func setTestButtonProperties(_ testButton: UIButton, _ view: UIView) {
        testButton.setTitle("Test Button", for: .normal)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.layer.zPosition = 1000
        view.addSubview(testButton)
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    public static func handleOrientation() {
        // will be implemented
    }
    
}
