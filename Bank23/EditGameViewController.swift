//
//  EditGameViewController.swift
//  Bank23
//
//  Created by Ian Vonseggern on 12/28/16.
//  Copyright © 2016 Ian Vonseggern. All rights reserved.
//

import UIKit

enum selectedButton {
  case piece(Piece)
  case increment(Int)
  case none
}

final class EditGameViewController: UIViewController {
  var _board = Board()
  var _pieces = [Piece]()
  var _view: EditGameView
  var _selectedPiece: Piece?
  var _rows = 5
  var _columns = 5
  
  var levelMenuController: LevelMenuController?

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    _view = EditGameView(frame:CGRect.zero)

    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    _view = EditGameView(frame:CGRect.zero)

    super.init(coder: aDecoder)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view = _view
    
    do {
      _board = try Board(initialBoard: Array(repeating:Array(repeating:Piece.empty, count:_rows), count:_columns))
      _view._board.updateModel(board: _board._board)
    } catch {
      print("Can't initialize board")
    }
    
    _view._backButton.addTarget(self, action: #selector(didTapBack), for: UIControlEvents.touchUpInside)
    _view._saveButton.addTarget(self, action: #selector(didTapSave), for: UIControlEvents.touchUpInside)

    _view.isUserInteractionEnabled = true
    _view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userDidTap(gesture:))))
    
    _pieces.append(Piece.coins(0))
    _pieces.append(Piece.sand(0))
    _view._remainingPieces.updatePiecesLeft(pieces: _pieces)
  }
  
  func userDidTap(gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: _view)
    let hitView = _view.hitTest(location, with: nil)
    if hitView is PieceView {
      let pieceView = hitView as! PieceView
      if (pieceView.superview is BoardView) {
        didTapBoard(at: location)
      } else if (pieceView.superview is RemainingPiecesView) {
        didTapRemainingPieces()
      } else {
        didTapPieceButton(pieceView: pieceView)
      }
    }
    
    if hitView is BoardView {
      didTapBoard(at: location)
    }
    
    if hitView is RemainingPiecesView {
      didTapRemainingPieces()
    }
  }// grandma's wifi password: anieldrm
  
  func didTapPieceButton(pieceView: PieceView) {
    // If you select the same piece we swap between increment and decrement
    if _selectedPiece != nil && pieceView._model.sameType(otherPiece: _selectedPiece!) {
      _selectedPiece = _selectedPiece?.increment(-2 * (_selectedPiece?.value())!)
      pieceView.setPiece(model: _selectedPiece!)
      pieceView.setNeedsLayout()
    } else {
      _selectedPiece = pieceView._model
    }
    
    // Set background colors
    for otherPieceView in _view._pieceButtons {
      if otherPieceView == pieceView {
        pieceView.backgroundColor = UIColor.lightGray
      } else {
        otherPieceView.backgroundColor = UIColor.white
      }
    }
  }
  
  func didTapBoard(at: CGPoint) {
    if (_selectedPiece == nil) {
      return
    }
    
    let boardOrigin = _view._board.frame.origin
    let column = Int(floor((at.x - boardOrigin.x) / SINGLE_SQUARE_SIZE))
    let row = _board.rowCount() - 1 - Int(floor((at.y - boardOrigin.y) / SINGLE_SQUARE_SIZE))
    
    let existingPiece = _board._board[column][row]
    var pieceToAdd = _selectedPiece!
    if (_selectedPiece != nil && existingPiece.sameType(otherPiece: _selectedPiece!)) {
      pieceToAdd = existingPiece.increment(_selectedPiece!.value())
    }
    if pieceToAdd.value() < 1 {
      pieceToAdd = Piece.empty
    }
    _board.addPiece(piece: pieceToAdd, row: row, column: column)
    
    _view._board.updateModel(board: _board._board)
  }
  
  func didTapRemainingPieces() {
    if (_selectedPiece == nil || !_selectedPiece!.moves()) {
      return
    }
    
    var newPieces = [Piece]()
    for piece in _pieces {
      if _selectedPiece!.sameType(otherPiece: piece) && (piece.value() + _selectedPiece!.value() >= 0) {
        newPieces.append(piece.increment(_selectedPiece!.value()))
      } else {
        newPieces.append(piece)
      }
    }
    _pieces = newPieces
    _view._remainingPieces.updatePiecesLeft(pieces: _pieces)
  }
  
  func didTapBack() {
    let _ = self.navigationController?.popViewController(animated: true)
  }
  
  func didTapSave() {
    if _view._name.text == "" {
      let alert = UIAlertController(title: nil,
                                    message: "You must add a name",
                                    preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
      
      return
    }
    
    // We actually represent initialPieces with an array of 1 pieces instead so switch representations
    var initialPieces = [Piece]()
    for piece in _pieces {
      let newPieces = Array.init(repeating: piece.increment(1 - piece.value()), count: piece.value())
      initialPieces.append(contentsOf: newPieces)
    }
    levelMenuController!.add(board: _board._board, initialPieces: initialPieces, withName: _view._name.text!)
    
    let _ = self.navigationController?.popViewController(animated: true)
  }
}
