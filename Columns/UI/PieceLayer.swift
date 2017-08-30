//
//  PieceLayer.swift
//  Columns
//
//  Created by Greg Sutton on 27/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import UIKit

class PieceLayer: CALayer {
    var piece: Piece
    var valueLayers: [CATextLayer] = []
    
    init( piece: Piece, valueSize: CGSize ) {
        self.piece = piece
        
        super.init()
        
        let fontSize = valueSize.height / 1.2
        
        var vOffset: CGFloat = 0.0
        
        for _ in 0...2 {
            let textLayer = CATextLayer()

            textLayer.fontSize = fontSize
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.frame = CGRect( x: 0.0, y: vOffset, width: valueSize.width, height: valueSize.height )
            valueLayers.append( textLayer )
            self.addSublayer( textLayer )
            vOffset += valueSize.height
        }

        self.bounds = CGRect( x: 0.0, y: 0.0, width: valueSize.width, height: valueSize.height * 3.0 )
        
        updateValues()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Probably because of being a backing layer, recreating from a backing layer
    override init(layer: Any) {
        guard let pieceLayer = layer as? PieceLayer else { fatalError("init(coder:) has not been implemented") }
        
        self.piece = pieceLayer.piece
        
        super.init()
        
        self.frame = pieceLayer.frame   // Needed to stop it animating from 0, 0
    }
    
    func updateValues() {
        guard 3 == valueLayers.count else { return }
        for i in 0...2 {
            valueLayers[i].string = piece.values[i].rawValue
        }
    }
}
