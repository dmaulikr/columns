//
//  GridView.swift
//  Columns
//
//  Created by Greg Sutton on 27/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import UIKit

class GridView: UIView {
    override class var layerClass: AnyClass {
        return GridLayer.self
    }
    
    override func draw(_ rect: CGRect) {
        
    }
}
