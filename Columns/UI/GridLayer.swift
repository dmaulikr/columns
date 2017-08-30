//
//  GridLayer.swift
//  Columns
//
//  Created by Greg Sutton on 27/03/2016.
//  Copyright © 2016 Darksheep. All rights reserved.
//

import UIKit

class GridLayer: CALayer {
    let lineColor = UIColor.lightGray.cgColor
    let backColor = UIColor.gray.cgColor
    
    var tileGrid: [[TileLayer?]] = []
    
    var currentPieceLayer: PieceLayer?
    
    // We'll do these lazily assuming size does not change - otherwise make them computed
    lazy var cellWidth: CGFloat = {
        let width = self.frame.width
        let result = width / CGFloat( cGridWidth )
        return result
    }()

    lazy var cellHeight: CGFloat = {
        let height = self.frame.height
        let result = height / CGFloat( cGridHeight )
        return result
    }()
    
    lazy var cellSize: CGSize = {
        return CGSize( width: self.cellWidth, height: self.cellHeight )
    }()

    override init() {
        super.init()
        
        self.isGeometryFlipped = true
        self.masksToBounds = true
        
//        self.backgroundColor = backColor
        
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.newGame(_:) ), name: cNotificationGamePlaying, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.endGame(_:) ), name: cNotificationGameEnd, object: nil )

        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.addTiles(_:) ), name: cNotificationAddTiles, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.removeTiles(_:) ), name: cNotificationRemoveTiles, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.moveTilesDown(_:) ), name: cNotificationMoveTilesDown, object: nil )

        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceRemove(_:) ), name: cNotificationPieceRemove, object: nil )
        
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceNew(_:) ), name: cNotificationPieceNew, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceDown(_:) ), name: cNotificationPieceDown, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceRotate(_:) ), name: cNotificationPieceRotate, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceDrop(_:) ), name: cNotificationPieceDrop, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceLeftRight(_:) ), name: cNotificationPieceLeft, object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( GridLayer.pieceLeftRight(_:) ), name: cNotificationPieceRight, object: nil )
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw( in ctx: CGContext ) {
        let width = self.frame.width
        let height = self.frame.height
        
        ctx.setFillColor( backColor )
        ctx.fill( self.bounds )
        
        ctx.setStrokeColor( lineColor )
        ctx.setLineWidth( 1.5 )
        
        //CGContextStrokeRect( ctx, self.bounds )
        
        let widthStep = cellWidth
        let heightStep = cellHeight
        
        // Take the minimum of these and start lesser one with offset? so we keep a square
        // At the moment I'm just going to set the size
        
        var step: CGFloat = 0.0
        while step <= width {
            ctx.move(to: CGPoint(x: step, y: 0.0))
            ctx.addLine(to: CGPoint(x: step, y: height))
            ctx.strokePath()
            step += widthStep
        }
        
        step = 0.0
        while step <= height {
            ctx.move(to: CGPoint(x: 0.0, y: step))
            ctx.addLine(to: CGPoint(x: width, y: step))
            ctx.strokePath()
            step += heightStep
        }
    }
    
    func updatePieceLayerPosition( _ pieceLayer: PieceLayer, time: Double = 0.0 ) {
        let location = pieceLayer.piece.location
        let width = pieceLayer.frame.width
        let height = pieceLayer.frame.height
        let x = CGFloat( location.x ) * cellWidth
        let y = CGFloat( location.y ) * cellHeight
        let newFrame = CGRect( x: x, y: y, width: width, height: height )
        
        if 0.0 == time {
            pieceLayer.frame = newFrame
        }
        else {
            // Set the time of the animation
            pieceLayer.removeAnimation( forKey: "position" )
            
            let animation = CABasicAnimation( keyPath: "position" )
            // Animating from the fromValue stops the animation resetting itself to the old position
            animation.fromValue = pieceLayer.value( forKey: "position" )
            pieceLayer.position = CGPoint( x: newFrame.midX, y: newFrame.midY )
            animation.timingFunction = CAMediaTimingFunction( name: kCAMediaTimingFunctionLinear )
            animation.duration = time
            pieceLayer.add( animation, forKey: "position" )
        }
        
        setNeedsDisplay( newFrame )
    }
    
    func updateTilelayerPosition( _ tileLayer: TileLayer ) {
        let location = tileLayer.tile.location
        let width = tileLayer.frame.width
        let height = tileLayer.frame.height
        let x = CGFloat( location.x ) * cellWidth
        let y = CGFloat( location.y ) * cellHeight
        let newFrame = CGRect( x: x, y: y, width: width, height: height )
        tileLayer.frame = newFrame
    }
}

// MARK: Notifications
extension GridLayer {
    @objc func newGame( _ notification: Notification ) {
        tileGrid = Array( repeating: Array(repeating: nil, count: cGridHeight ), count: cGridWidth )
        currentPieceLayer = nil
        sublayers = nil
    }
    
    @objc func endGame( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece else { return }
        
        let x = piece.location.x
        for y in 0..<cGridHeight {
            if let tile = tileGrid[x][y] {
                tile.foregroundColor = UIColor.yellow.cgColor
            }
            else {
                print( "\(type( of: self )).endGame no tile \(x), \(y)" )
            }
        }
    }
    
    @objc func addTiles( _ notification: Notification ) {
        guard let tiles = notification.userInfo?[cNotificationKeyTiles] as? [Tile] else { return }
        for tile in tiles {
            let location = tile.location
            if location.y >= cGridHeight {
                continue
            }
            let layer = TileLayer( tile: tile, valueSize: cellSize )
            updateTilelayerPosition( layer )
            if nil != tileGrid[location.x][location.y] {
                print( "\(type( of: self )).addTiles adding to existant tile \(location)" )
            }
            tileGrid[location.x][location.y] = layer
            addSublayer( layer )
        }
    }
    
    @objc func removeTiles( _ notification: Notification ) {
        guard let tiles = notification.userInfo?[cNotificationKeyTiles] as? [Tile] else { return }
        for tile in tiles {
            let location = tile.location
            if let layer = tileGrid[location.x][location.y] {
                tileGrid[location.x][location.y] = nil
                layer.removeFromSuperlayer()
            }
            else {
                print( "GridLayer.removeTiles removing non-existant tile \(location)" )
            }
        }
    }
    
    @objc func moveTilesDown( _ notification: Notification ) {
        guard let tiles = notification.userInfo?[cNotificationKeyTiles] as? [Tile], let delta = notification.userInfo?[cNotificationKeyDelta] as? Int else { return }
        for tile in tiles {
            let location = tile.location
            if let tileLayer = tileGrid[location.x][location.y] {
                tileGrid[location.x][location.y] = nil
                tileGrid[location.x][location.y - delta] = tileLayer
                tileLayer.tile = Tile( location: Location( x: location.x, y: location.y - delta ), value: tile.value )
                updateTilelayerPosition( tileLayer )
            }
        }
    }
    
    @objc func pieceRemove( _ notification: Notification ) {
        guard let pieceLayer = currentPieceLayer else { return }
        pieceLayer.removeFromSuperlayer()
        currentPieceLayer = nil
    }
    
    @objc func pieceNew( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece else { return }
        let layer = PieceLayer( piece: piece, valueSize: cellSize )
        currentPieceLayer = layer
        updatePieceLayerPosition( layer )
        
        print( "\(type( of: self )).pieceNew \(piece.values[0]) \(piece.values[1]) \(piece.values[2])" )
        
        addSublayer( layer )
    }
    
    @objc func pieceDown( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece, let pieceLayer = currentPieceLayer else { return }
        guard let time = notification.userInfo?[cNotificationKeyTime] as? Double else { return }
        pieceLayer.piece = piece
        updatePieceLayerPosition( pieceLayer, time: time )
    }
    
    @objc func pieceRotate( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece, let pieceLayer = currentPieceLayer else { return }
        pieceLayer.piece = piece
        pieceLayer.updateValues()
    }
    
    @objc func pieceDrop( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece, let pieceLayer = currentPieceLayer else { return }
        guard let time = notification.userInfo?[cNotificationKeyTime] as? Double else { return }
        pieceLayer.piece = piece
        updatePieceLayerPosition( pieceLayer, time: time )
    }
    
    @objc func pieceLeftRight( _ notification: Notification ) {
        guard let piece = notification.userInfo?[cNotificationKeyPiece] as? Piece, let pieceLayer = currentPieceLayer else { return }
        pieceLayer.piece = piece
        updatePieceLayerPosition( pieceLayer )
    }
}
