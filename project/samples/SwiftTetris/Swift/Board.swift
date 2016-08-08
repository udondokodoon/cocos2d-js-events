
/****************************************************************************
Copyright (c) 2014 Chukong Technologies Inc.

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

//  Board.swift
//  Created by Justin Graham on 6/27/14.

import CoreGraphics

//
// Constants
//
let COLUMNS : Int = 10
let ROWS : Int = 17

class Board : Node
{
    struct MapEntry
    {
        var block : Block? = nil
        var cell  : Node?  = nil
    }
    
    var _hud : LayerColor? = nil
    var _scoreLabel : Label? = nil
    
    var _map : [MapEntry] = []

    var _accelerometer : EventListenerAcceleration?
    var _blocks : [Block] = []
    var _currentBlock : Block?

    var _falling : Bool = false
    var _lastDropSpeed : Float = 0.5
    var _dropSpeed : Float = 0.5
    var _altDropSpeed : Float = 0.1
    var _startFallingDelay : Float = 0.1
    var _time      : Float = 0
    
    var _countdownDelay : Float = 0.5
    var _gameDelay : Float = 1
    var _gameTime : Float = 0
    var _countDown : Int = 3
    
    var _origin : CGPoint = CGPointZero
    var _size : CGSize = CGSizeZero
    var _blockSize : CGSize = CGSizeZero
    
    var _cellBL : FixedPoint = FixedPoint(x: 0, y: 0)
    var _cellTR : FixedPoint = FixedPoint(x: 0, y: 0)
    
    var _board : Node = Node()
    
    var _rowsCleared : Int = 0
    var _level : Int = 1
    var _numRowsNeededForNextLevel : Int = 5
    var _score : UInt = 0
    
    var _paused : Bool = false
    
    let DELAY : Float = 0.015
    let DELAY2 : Float = 0.05
    let DURATION : Float = 0.10
    let MOVE_TIME : Float = 0.05

    enum State
    {
        case LEVEL // Display level state
        case COUNTDOWN // Beginning state
        case IDLE // enter drop state
        case PAUSE // do nothing state
        case DROP // spawn a single random piece
        case PLAY // user interaction occurs until the piece has landed
        case DEAD // end case when a piece cannot be dropped
        case NEXTLEVEL // state cannot be changed once in this state
    }
    var _state : State = .LEVEL
    
    //
    // Methods
    //
    
    override init()
    {
        super.init()
        
        var director = Director.getInstance()
        var size = director.getWinSize()
        setContentSize(size)
        
        BlockFactory.getInstance.setBoard(self)
        var block = BlockFactory.getInstance.loadColoredBlock(7)
        var blockSize = block.getContentSize()
        _blockSize = blockSize
        
        var listener = EventListenerTouchOneByOne()
        listener.onTouchBegan = touchBoard
        
        director.eventDispatcher.addEventListenerWithSceneGraphPriority(listener, _board)

        director.console.addCommand("dumpMap", "dumps the map to console", commandDumpMap)
    }
    
    func commandDumpMap(i : CInt, s : String!)
    {
        Debug.getInstance.log("")

        var t = "IJLOSTZE"
        var types = Array(t)
        var line : String
        for r in 0..<ROWS
        {
            line = ""
            
            for c in 0..<COLUMNS
            {
                var cell = FixedPoint(x : Fixed(c), y : Fixed((ROWS-1) - r))
                var index = cellToIndex(cell)
                var block = _map[index].block
                if nil == block
                {
                    line += "."
                }
                else
                {
                    var type = block!.getType()
                    var s = String(types[type])
                    line += s
                }
            }
            
            line += "    "
            
            for c in 0..<COLUMNS
            {
                var cell = FixedPoint(x : Fixed(c), y : Fixed((ROWS-1) - r))
                var index = cellToIndex(cell)
                var cc = _map[index].cell
                if nil == cc
                {
                    line += "."
                }
                else
                {
                    var type = _map[index].block!.getType()
                    var s = String(types[type])
                    line += s
                }
            }
            
            Debug.getInstance.log(line)
        }
        
        Debug.getInstance.log("")
    }

    func togglePause()
    {
        _paused = !_paused
    }
    
    func bottomLeftInPoints() -> CGPoint
    {
        var l = CGFloat(Float(_cellBL.x)) * _blockSize.width
        var b = CGFloat(Float(_cellBL.y)) * _blockSize.height
        return CGPointMake(l, b)
    }
    
    func topRightInPoints() -> CGPoint
    {
        var t = CGFloat(Float(_cellTR.x)) * _blockSize.width
        var r = CGFloat(Float(_cellTR.y)) * _blockSize.height
        return CGPointMake(t, r)
    }
    
    func touchBoard(touch : Touch!, event : Event!) -> Bool
    {
        if _state != .PLAY
        {
            return false;
        }
        
        if nil != pickBlockFromLocation(touch.getLocation())
        {
            rotatePiece(touch, event: event)
            return true;
        }
        
        // the board has been touched
        var point = touch.getLocation()
        var halfway = _size.width / 2
        
        if point.x <= halfway
        {
            moveCurrentBlockLeft()
        }
        else
        {
            moveCurrentBlockRight()
        }
        
        return true
    }
    
    func gameOver()
    {
        self.unscheduleUpdate()
        _blocks = []
        _currentBlock = nil
        _map = []

        var scene = SceneMenu()
        var fade = TransitionFade.create(3, scene)
        Director.getInstance().replaceScene(fade)
    }
    
    func nextLevel()
    {
        AudioEngine.playEffect("oh_yeah.mp3", false, 22050, 0, 1)

        var parent = getParent() as SceneGame
        parent.nextLevel(_score)
        setState(.NEXTLEVEL)
    }
    
    func fillBackground()
    {
        var director = Director.getInstance()
        var size = director.getWinSize()
        
        var across : Int = Int(size.width  / _blockSize.width)
        var down : Int   = Int(size.height / _blockSize.height)
        
        var l = (across - COLUMNS) / 2
        var r = l + COLUMNS - 1
        var b = 1
        var t = b + ROWS - 1
        
        _cellBL = FixedPoint(x: Fixed(b), y: Fixed(l))
        _cellTR = FixedPoint(x: Fixed(r), y: Fixed(t))
        
        //Debug.getInstance.log("across \(across) down \(down) l \(l) r \(r) t \(t) b \(b)")
        
        for d in 0..<down
        {
            for a in 0..<across
            {
                if d >= b && d <= t && a >= l && a <= r
                {
                    continue
                }
                
                var block = BlockFactory.getInstance.loadColoredBlock(7)
                block.setPosition(CFloat(a * Int(_blockSize.width)), CFloat(d * Int(_blockSize.height)))
                _board.addChild(block)
            }
        }
        
        var backWidth  = _blockSize.width  * CGFloat(across)
        var backHeight = _blockSize.height * CGFloat(down)
        var left = (size.width - backWidth) / 2.0
        var bott = (size.height - backHeight) / 2.0
        _board.setPosition(CGPointMake(left, bott))
        
        _origin = CGPointMake(left, bott)
        _size = CGSizeMake(CGFloat(r - l) * _blockSize.width, CGFloat(t - b) * _blockSize.height)
        
        self.addChild(_board)
    }
    
    func start()
    {
        for i in 0..<COLUMNS * ROWS
        {
            _map.append(MapEntry())
        }
        
        var director = Director.getInstance()
        var size = director.getWinSize()
                
        self.fillBackground()
        
        var w : Float = 0.75 * Float(size.width)
        var h : Float = 0.12 * Float(size.height)
        var color = Color4B.createWithRGBA(0, 0, 0, 128) as Color4B
        _hud = LayerColor.create(color, w, h);
        _hud?.setPosition(CGPointMake(0.5 * (size.width - CGFloat(w)), 0.845 * size.height))
        addChild(_hud)
        
        _scoreLabel = Label.createWithTTF("Score: \(_score)", "Arcade.ttf", 70)
        _scoreLabel!.setAnchorPoint(CGPointMake(0.5, 0.5))
        _hud!.addChild(_scoreLabel!)
        _scoreLabel!.setNormalizedPosition(CGPointMake(0.5, 0.5))
    }
    
    override func onEnterTransitionDidFinish()
    {
        displayLevel()
        self.scheduleUpdate(update)
    }
    
    func startCountDown()
    {
        if _countDown < 0
        {
            return
        }

        AudioEngine.playEffect("go.mp3", false, 22050, 0, 1)
    
        var director = Director.getInstance()
        var size = director.getWinSize()
        
        var text = _countDown > 0 ? "\(_countDown)" : ""
        var grey = Color4B.createWithRGBA(128, 128, 128, 128) as Color4B
        var label = Label.createWithTTF(text, "Arcade.ttf", 180)
        label.setPosition(CGPointMake(size.width / 2, size.height / 2))
        label.enableShadow(grey, CGSizeMake(0.8 * 5, -5), 50)
        self.addChild(label)

        var actions : Array<Action> = []
        
        actions.append(ClosureAction.createWithDuration(_countdownDelay, { (time : Float) -> Void in
            label.setScale(1 / time)
            }))
        
        actions.append(ClosureAction.createWithDuration(_countdownDelay, { (time : Float) -> Void in
            label.removeFromParentAndCleanup(true)
            }))
        
        var sequence = Sequence.create(actions)
        
        label.runAction(sequence)
        
        --_countDown
    }
    
    func cellToIndex(cell : FixedPoint) -> Int
    {
        var x = Int(cell.x) >= COLUMNS ? COLUMNS - 1 : Int(cell.x)
        var y = Int(cell.y) >= ROWS    ? ROWS - 1    : Int(cell.y)
        return Int(y * COLUMNS + x)
    }
    
    func canPlaceBlock(block : Block) -> Bool
    {
        var cells : Array<FixedPoint> = block.getCells()
        for p in cells
        {
            //Debug.getInstance.log("checking cell \(p.x), \(p.y) against \(_cellBL.x), \(_cellBL.y) -> \(_cellTR.x), \(_cellTR.y)")
            if p.x < 0 || p.x >= Fixed(COLUMNS)
            {
                Debug.getInstance.log("canPlaceBlock x: out of range \(p.x), \(p.y)")
                return false;
            }
            if p.y < 0 || p.y >= Fixed(ROWS)
            {
                Debug.getInstance.log("canPlaceBlock y: out of range \(p.x), \(p.y)")
                return false;
            }
            var index = cellToIndex(p)
            if index >= _map.count
            {
                Debug.getInstance.log("canPlaceBlock: invalid index \(index)")
                return false
            }
            if (index < 0)
            {
                Debug.getInstance.log("canPlaceBlock: invalid index \(index)")
                return false
            }
            if nil != _map[index].block
            {
                return false
            }
        }
        return true;
    }
    
    func spawnBlock() -> Bool
    {
        var block = BlockFactory.getInstance.createRandomBlock()
        placeBlockInPlayArea(&block)
        
        if false == canPlaceBlock(block)
        {
            Debug.getInstance.log("DEAD")
            setState(.DEAD)
            return false
        }
        
        block.addToMap()

        var touchListener = EventListenerTouchOneByOne()
        var keybdListener = EventListenerKeyboard()
        
        keybdListener.onKeyPressed = keyboardPressed
        keybdListener.onKeyReleased = keyboardReleased
        
        var director = Director.getInstance()
        director.eventDispatcher.addEventListenerWithSceneGraphPriority(touchListener, block)
        director.eventDispatcher.addEventListenerWithSceneGraphPriority(keybdListener, block)
        
        AudioEngine.playEffect("drop.mp3", false, 22050, 0, 1)

        return true
    }
    
    func cleanupCurrentBlock()
    {
        if nil != _currentBlock
        {
            Director.getInstance().eventDispatcher.removeEventListenersForTarget(_currentBlock, false)
        }
    }
    
    func placeBlockInPlayArea(inout block : Block)
    {
        var piece = block.getPiece()
        
        var l = 0 - piece.BL().x
        var r = Fixed(COLUMNS) - piece.TR().x
        
        var slot = Int(Utilities.random(Double(l), Double(r)))
        
        var x = slot
        var y = ROWS - Int(piece.TR().y)
        
        block.setPos(FixedPoint(x: Fixed(x), y: Fixed(y)))
        
        _board.addChild(block)
        _blocks.append(block)
        _currentBlock = block
    }
    
    func clampBlockToPlayArea(block : Block)
    {
        var piece = block.getPiece()
        
        var l = 0 - piece.BL().x
        var r = Fixed(COLUMNS) - piece.TR().x
        var t = Fixed(ROWS) - piece.TR().y
        var b = 0 - piece.BL().y
        
        //Debug.getInstance.log("clamping block to \(l), \(r) -> \(t), \(b)")
        
        var pos = block.getPos()
        
        //Debug.getInstance.log("old pos \(pos.x), \(pos.y)")
        
        pos.x = pos.x < l ? l : pos.x
        pos.x = pos.x > r ? r : pos.x
        pos.y = pos.y < b ? b : pos.y
        pos.y = pos.y > t ? t : pos.y
        
        block.setPos(pos)
    
        //Debug.getInstance.log("piece pos \(pos.x), \(pos.y)")
    }
    
    func moveCurrentBlock()
    {
        var block = _currentBlock!
        var cell = block.getPos()
        
        if cell.y == 0
        {
            // remove the block from the map once it reaches here to avoid anyone being able to use it
            // the block is no frozen and only its cells matter from this point on
            var cells = block.getCells()
            for cc in cells
            {
                var index = cellToIndex(cc)
                _map[index].block = nil;
            }
            setState(.IDLE)
            return
        }
        
        block.removeFromMap()
        var pos = block.getPos()
        var newPos = pos
        --newPos.y
        clampBlockToPlayArea(block)
        block.setPos(newPos)

        if !canPlaceBlock(block)
        {
            block.setPos(pos)
            setState(.IDLE)
        }
        block.addToMap()
    }
    
    func moveCurrentBlockLeft()
    {
        var block = _currentBlock!
        block.removeFromMap()
        var pos = block.getPos()
        var newPos = pos
        --newPos.x
        clampBlockToPlayArea(block)
        //Debug.getInstance.log("moveCurrentBlockLeft: moving block from \(pos.x), \(pos.y) to \(newPos.x), \(newPos.y)")
        block.setPos(newPos)
        if !canPlaceBlock(block)
        {
            block.setPos(pos)
        }
        else
        {
            AudioEngine.playEffect("move.mp3", false, 22050, 0, 1)
        }
        block.addToMap()
    }
    
    func moveCurrentBlockRight()
    {
        var block = _currentBlock!
        block.removeFromMap()
        var pos = block.getPos()
        var newPos = pos
        ++newPos.x
        clampBlockToPlayArea(block)
        //Debug.getInstance.log("moveCurrentBlockRight: moving block from \(pos.x), \(pos.y) to \(newPos.x), \(newPos.y)")
        block.setPos(newPos)
        if !canPlaceBlock(block)
        {
            block.setPos(pos)
        }
        else
        {
            AudioEngine.playEffect("move.mp3", false, 22050, 0, 1)
        }
        block.addToMap()
    }
    
    func pickBlockFromLocation(location : CGPoint) -> Block?
    {
        for block in _blocks
        {
            var piece  = block.getPiece()
            
            for object : AnyObject in piece.getChildren()
            {
                var cell = object as Sprite
                var size = cell.getContentSize()
                var np = cell.convertToNodeSpace(location)
                if np.x >= 0 && np.y >= 0 && np.x < size.width && np.y < size.height
                {
                    return block;
                }
            }
        }
        return nil
    }
    
    func rotatePiece(touch : Touch!, event : Event!) -> Bool
    {        
        let block = _currentBlock
        if nil == block
        {
            return false
        }
        var b = block!

        var rotation = b.getRot()
        
        b.removeFromMap()
        
        var newrot = (rotation + 1) % 4
        
        b.setRot(newrot)
        
        clampBlockToPlayArea(b)
        
        if !canPlaceBlock(b)
        {
            b.setRot(rotation)
        }
        
        b.addToMap()
        
        return true
    }
    
    func keyboardReleased(keycode : KeyCode, event : Event!)
    {
        switch keycode
        {
        case .CodeDOWN_ARROW:
            _dropSpeed = _lastDropSpeed
        
        default:
            break
        }
    }
    
    func keyboardPressed(keycode : KeyCode, event : Event!)
    {
        switch keycode
        {
        case .CodeP:
            togglePause()
            
        case .CodeLEFT_ARROW:
            moveCurrentBlockLeft()
            
        case .CodeRIGHT_ARROW:
            moveCurrentBlockRight()
            
        case .CodeDOWN_ARROW:
            _lastDropSpeed = _dropSpeed
            _dropSpeed = _altDropSpeed
            
        case .CodeUP_ARROW:
            rotatePiece(nil, event: event)
            
        case .CodeSPACE:
            startFallingPiece()

        default:
            break
        }
    }
    
    func convertWorldPositionToCell(pos : CGPoint) -> FixedPoint
    {
        var cx = Fixed(Int((pos.x - _origin.x) / _blockSize.width)) - Fixed(_cellBL.x)
        var cy = Fixed(Int((pos.y - _origin.y) / _blockSize.height)) - Fixed(_cellBL.y)
        return FixedPoint(x: cx, y: cy)
    }

    func getSpriteForCellFromBlock(block : Block, cell : FixedPoint) -> Sprite?
    {
        var piece = block.getPiece()
        for c in piece.getChildren()
        {
            var sprite = c as Sprite
            var wp = sprite.convertToWorldSpace(CGPointZero)
            var cc = convertWorldPositionToCell(wp)
            if cc.x == cell.x && cc.y == cell.y
            {
                return sprite
            }
        }
        return nil
    }
    
    func addToMap(block : Block, cell : FixedPoint) -> Bool
    {
        var index = cellToIndex(cell)
        if index >= _map.count
        {
            Debug.getInstance.log("addToMap: invalid index \(index) count \(_map.count)")
            return false
        }
        if _map[index].block != nil
        {
            Debug.getInstance.log("addToMap: error cell \(cell.x), \(cell.y) block is already occupied")
            return false;
        }
        if _map[index].cell != nil
        {
            Debug.getInstance.log("addToMap: error cell \(cell.x), \(cell.y) cell is already occupied")
            return false;
        }
        var sprite = getSpriteForCellFromBlock(block, cell:cell)
        if sprite == nil
        {
            Debug.getInstance.log("addToMap: error cell \(cell.x), \(cell.y) could not find sprite for cell")
            return false;
        }
        _map[index].block = block
        _map[index].cell = sprite
        return true
    }
    
    func removeFromMap(block : Block, cell : FixedPoint) -> Bool
    {
        var index = cellToIndex(cell)
        if index >= _map.count
        {
            Debug.getInstance.log("removeFromMap: invalid index \(index) count \(_map.count)")
            return false
        }
        if _map[index].block != block
        {
            Debug.getInstance.log("removeFromMap: cell \(cell.x), \(cell.y) doesn't belong to block")
            return false
        }
        _map[index] = MapEntry()
        return true
    }

    func removeRow(row : Fixed)
    {
        setState(.PAUSE)
        
        for c in 0 ..< COLUMNS
        {
            // first remove the cells in the row
            var index = cellToIndex(FixedPoint(x : Fixed(c), y : Fixed(row)))

            var cell = _map[index].cell
            if nil != cell
            {
                var delay = ClosureAction.createWithDuration(DELAY * Float(COLUMNS - c), { (time : Float) -> Void in
                    })
                
                var speed : Float = 0.0
                var flyoff = ClosureAction.createWithDuration(DURATION, { (time : Float) -> Void in
                    speed = 50.0 * time
                    var pos = cell!.getPosition()
                    pos.x += CGFloat(speed)
                    cell!.setPosition(pos)
                })
                
                var remove = ClosureAction.createWithDuration(0, { (time : Float) -> Void in
                    self.addScore(1)
                    cell!.removeFromParentAndCleanup(true)
                })
                
                var sequence = delay + flyoff + remove
                cell!.runAction(sequence)

                _map[index].cell = nil
            }
        }
        
        // we don't move the row down until the pieces have flown off
        // and we stay in a paused state while this happens.
        var rowDelay = DELAY * Float(COLUMNS)
        var delay = DelayTime.create(rowDelay)
        
        var moveRows = ClosureAction.createWithDuration(0, { (time : Float) in
            // now move all the rows above down
            var start = Int(row)
            for r in start ..< ROWS
            {
                for c in 0 ..< COLUMNS
                {
                    var index = self.cellToIndex(FixedPoint(x : Fixed(c), y : Fixed(r)))
                    
                    // move the cell above to match
                    if r < (ROWS - 1)
                    {
                        var above = self.cellToIndex(FixedPoint(x : Fixed(c), y : Fixed(r + 1)))
                        
                        var cc = self._map[above].cell
                        if (nil != cc)
                        {
                            var pos = cc!.getPosition()
                            pos.y -= self._blockSize.height
                            var move = MoveTo.create(self.MOVE_TIME, pos)
                            cc!.runAction(move)
                        }
                        
                        self._map[index] = self._map[above]
                        self._map[above] = MapEntry()
                    }
                    else
                    {
                        self._map[index] = MapEntry()
                    }
                }
            }
        })
        
        var delay2 = DelayTime.create(DELAY2)
        
        var nextState = ClosureAction.createWithDuration(0, { (time : Float) in
            AudioEngine.playEffect("line.mp3", false, 22050, 0, 1)
            self.setState(.IDLE)
        })
        
        var actions = delay + moveRows + delay2 + nextState
        
        runAction(actions)
    }
    
    func addScore(score : UInt)
    {
        _score += score
        _scoreLabel!.setString("Score: \(_score)")
    }
    
    func checkAndRemoveRows() -> Int
    {
        var removed = 0
        var row = 0
        for r in 0..<ROWS
        {
            var count = 0
            
            for c in 0..<COLUMNS
            {
                var index = cellToIndex(FixedPoint(x : Fixed(c), y : Fixed(row)))
                if _map[index].block != nil
                {
                    ++count
                }
            }
            
            if count == COLUMNS
            {
                ++removed
                removeRow(Fixed(row))
                return removed
            }
            else
            {
                ++row
            }
        }
        
        return removed
    }
    
    func startFallingPiece()
    {
        var block = _currentBlock!
        block.removeFromMap()
        var pos = block.getPos()
        var newPos = pos
        while newPos.y > 0
        {
            --newPos.y
            block.setPos(newPos)
            if !canPlaceBlock(block)
            {
                block.setPos(pos)
                break
            }
            pos.y = newPos.y
        }
        block.addToMap()
        setState(.PLAY)
        _time = 0
    }
    
    func displayLevel()
    {
        var label = Label.createWithTTF("Level \(_level)", "Arcade.ttf", 120)
        label.setAnchorPoint(CGPointMake(0.5, 0.5))
        var grey = Color4B.createWithRGBA(128, 128, 128, 128) as Color4B
        var blue = Color4B.createWithRGBA(88, 157, 214, 255) as Color4B
        label.setTextColor(blue)
        label.setOpacity(0.0)
        addChild(label)
        label.setNormalizedPosition(CGPointMake(0.5, 0.6))
        label.enableShadow(grey, CGSizeMake(0.8 * 20, -20), 50)

        var fadein = FadeIn.create(0.25)
        var delay = DelayTime.create(1)
        var fade = FadeOut.create(0.25)
        var remove = ClosureAction.createWithDuration(0, { (time : Float) -> Void in
            label.removeFromParentAndCleanup(true)
            })
        var next = ClosureAction.createWithDuration(0, { (time : Float) -> Void in
            self.setState(.COUNTDOWN)
            })
        var sequence = fadein + delay + fade + remove + next
        label.runAction(sequence)
        setState(.PAUSE)
    }
    
    func setState(state : State)
    {
        if _state != .NEXTLEVEL
        {
            _state = state
        }
    }
    
    func update(delta : Float)
    {
        switch _state
        {
        case .LEVEL:
            displayLevel()
            
        case .COUNTDOWN:
            if _countDown >= 0
            {
                _gameTime += delta
                while _gameTime >= _countdownDelay
                {
                    _gameTime -= _countdownDelay
                    startCountDown()
                }
                
                if _countDown >= 0
                {
                    return
                }
            }
            else
            {
                setState(.IDLE)
            }
        
        case .IDLE:
            var numRows = checkAndRemoveRows()
            _rowsCleared += numRows
            if _rowsCleared >= _numRowsNeededForNextLevel + _level
            {
                nextLevel()
            }
            if numRows == 0
            {
                setState(.DROP)
            }

        case .PAUSE:
            return
            
        case .DROP:
            // remove previous block listeners
            cleanupCurrentBlock()
            if spawnBlock()
            {
                setState(.PLAY)
            }
            
        case .PLAY:
            if _paused
            {
                return
            }
            
            _time += delta
            var speed = _dropSpeed
            while _time >= speed
            {
                _time -= speed
                moveCurrentBlock()
            }
            
        case .DEAD:
            gameOver()
            
        case .NEXTLEVEL:
            return
            
        default:
            Debug.getInstance.log("invalid state")
        }
    }
}
