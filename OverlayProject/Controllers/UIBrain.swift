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
    
    public static func getTeamOneText(_ max: CGFloat) -> CIImage {
        let teamOne = "Takım - 1"
        // create textRect for right top corner
        let textRect = CGRect(x: 50, y: 50, width: 500, height: max/2 + 25)
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 25)!
        ]
        let textImage = UIGraphicsImageRenderer(size: textRect.size).image { _ in
            teamOne.draw(in: textRect, withAttributes: textAttributes)
        }
        var textCiImage = CIImage(image: textImage)!
        textCiImage = textCiImage.oriented(CGImagePropertyOrientation.up)
        return textCiImage
    }
    
    public static func getTeamTwoText(_ max: CGFloat) -> CIImage {
        let teamTwo = "Takım - 2"
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont(name: "Helvetica Bold", size: 25)!
        ]
        let textRect2 = CGRect(x: 320, y: 50, width: 500, height: max/2 + 25)
        let textImage2 = UIGraphicsImageRenderer(size: textRect2.size).image { _ in
            teamTwo.draw(in: textRect2, withAttributes: textAttributes)
        }
        var textCiImage2 = CIImage(image: textImage2)!
        textCiImage2 = textCiImage2.oriented(CGImagePropertyOrientation.up)
        return textCiImage2
    }
    
}
