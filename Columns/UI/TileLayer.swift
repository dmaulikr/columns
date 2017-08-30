//
//  TileLayer.swift
//  Columns
//
//  Created by Greg Sutton on 28/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import UIKit

class TileLayer: CATextLayer {
    var tile: Tile
    
    init( tile: Tile, valueSize: CGSize ) {
        self.tile = tile
        
        super.init()
        
        let fontSize = valueSize.height / 1.2
        self.fontSize = fontSize
        self.alignmentMode = kCAAlignmentCenter
        self.string = tile.value.rawValue
        
        self.bounds = CGRect( x: 0, y: 0, width: valueSize.width, height: valueSize.height )
    }
    
    // Probably because of being a backing layer, recreating from a backing layer
    override init(layer: Any) {
        guard let pieceLayer = layer as? TileLayer else { fatalError("init(coder:) has not been implemented") }
        
        self.tile = pieceLayer.tile
        
        super.init()
        
        self.frame = pieceLayer.frame   // Needed to stop it animating from 0, 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
