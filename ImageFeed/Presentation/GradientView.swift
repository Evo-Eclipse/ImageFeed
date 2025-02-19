//
//  GradientView.swift
//  ImageFeed
//
//  Created by Pavel Komarov on 18.02.2025.
//

import UIKit

final class GradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let gradientLayer = self.layer as? CAGradientLayer {
            gradientLayer.colors = [
                UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0).cgColor,
                UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0.05).cgColor,
                UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0.2).cgColor
            ]
            
            gradientLayer.locations = [0.0, 0.5, 1.0]
        }
    }
}
