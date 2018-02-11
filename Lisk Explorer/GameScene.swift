// Copyright © 2018 Tagtaxa. All rights reserved.

import SpriteKit
import GameplayKit

class GameScene: SKScene, ServerDelegate, SKPhysicsContactDelegate {
   let server = Server()
   //let random = GKRandomSource.sharedRandom()

   override func didMove(to view: SKView) {
      server.delegate = self
      physicsWorld.contactDelegate = self

      func createPin(at location: CGPoint) {
         let radius: CGFloat = 10
         let pinNode = SKShapeNode(circleOfRadius: radius)
         pinNode.position = location
         pinNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
         //floorNode.physicsBody?.isDynamic = false
         pinNode.physicsBody?.pinned = true
         pinNode.physicsBody?.usesPreciseCollisionDetection = true
         if let mass = pinNode.physicsBody?.mass, let friction = pinNode.physicsBody?.friction {
            pinNode.physicsBody?.mass = mass * 30
            pinNode.physicsBody?.friction = friction * 2
         }
         pinNode.physicsBody?.restitution = 0.1

         self.addChild(pinNode)
      }

      func createFloor() {
         let cornerRadius: CGFloat = 6
         let floorSize = CGSize(width: self.frame.width - cornerRadius, height: 10)
         let floorNode = SKShapeNode(rectOf: floorSize, cornerRadius: cornerRadius)
         floorNode.position = CGPoint(x: 0, y: frame.minY + frame.height/8)
         floorNode.physicsBody = SKPhysicsBody(rectangleOf: floorSize)
         //floorNode.physicsBody?.isDynamic = false
         floorNode.physicsBody?.pinned = true
         floorNode.physicsBody?.usesPreciseCollisionDetection = true
         if let mass = floorNode.physicsBody?.mass, let friction = floorNode.physicsBody?.friction {
            floorNode.physicsBody?.mass = mass * 30
            floorNode.physicsBody?.friction = friction * 2
         }
         floorNode.physicsBody?.restitution = 0.1
         self.addChild(floorNode)
      }

      let fraction: CGFloat = 3.5
      createPin(at: CGPoint(x: -frame.width/fraction, y: frame.minY + frame.height/12))
      createPin(at: CGPoint(x: frame.width/fraction, y: frame.minY + frame.height/12))
      createFloor()
   }

   private func createBlockNode(rect: CGRect, block: Block) {
      let location = rect.origin
      let size = rect.size

      let rectNode = SKShapeNode(rectOf: size, cornerRadius: 4)
      rectNode.name = String(block.height)
      rectNode.userData = ["block": block]
      rectNode.position = location
      rectNode.physicsBody = SKPhysicsBody(rectangleOf: size)
      rectNode.physicsBody?.contactTestBitMask = 0x00000001
      if let mass = rectNode.physicsBody?.mass, let friction = rectNode.physicsBody?.friction {
         rectNode.physicsBody?.mass = mass * 3
         rectNode.physicsBody?.friction = friction * 1.5
      }
      rectNode.physicsBody?.restitution = 0.1

      let r = CGFloat(Double(random(1..<100)) / 100.0)
      rectNode.fillColor = NSColor(hue: 150/255,
                                   saturation: r,
                                   brightness: r,
                                   alpha: 1.0)
      rectNode.strokeColor = NSColor(white: 0.8, alpha: 1.0)

      let label = SKLabelNode(text: "\(block.height)")
      label.fontName = "HelveticaNeue-Bold"
      label.fontSize = 12
      label.position = CGPoint(x: label.position.x, y: label.position.y + size.width/3)
      rectNode.addChild(label)

      let label1 = SKLabelNode(text: String(format: "%.2f LSK", Double(block.totalAmount) / 1e8))
      label1.fontName = "HelveticaNeue-Bold"
      label1.fontSize = 15
      rectNode.addChild(label1)

      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss"
      let label2 = SKLabelNode(text: formatter.string(from: Date()))
      label2.fontName = "HelveticaNeue-Bold"
      label2.fontSize = 12
      label2.position = CGPoint(x: label2.position.x, y: label2.position.y - size.width/4)
      rectNode.addChild(label2)

      let formatter1 = DateFormatter()
      formatter1.dateFormat = "yyyy-MM-dd"
      let label3 = SKLabelNode(text: formatter1.string(from: Date()))
      label3.fontName = "HelveticaNeue-Bold"
      label3.fontSize = 12
      label3.position = CGPoint(x: label3.position.x, y: label3.position.y - size.width/2.5)
      rectNode.addChild(label3)

      self.addChild(rectNode)
   }

   override func mouseDown(with event: NSEvent) {
      if event.modifierFlags.contains(.option) {
         let location = event.location(in: self)
         let block = Block(height: 987654, totalAmount: random(123456789..<987654321))
         createBlockNode(rect: CGRect(origin: location, size: size(for: block)), block: block)
      }
   }

   func didEnd(_ contact: SKPhysicsContact) {
      //print(contact.bodyA.node?.name, contact.bodyB.node?.name)
   }

   func blocksDidChange(_ block: Block) {
      removeOffScreenNodes()

      if block.totalAmount == 0 {
         return
      }
      let s = size(for: block)

      let minX = Int(-frame.width/2 + s.width)
      let maxX = Int(frame.width/2 - s.width)
      let x = random(minX..<maxX)

      let minY = 0
      let maxY = Int(frame.height/2 - s.width)
      let y = random(minY..<maxY)

      //print(frame.width, frame.height, x, y, s)
      //print(self.children.count)
      let location = CGPoint(x: x, y: y)
      createBlockNode(rect: CGRect(origin: location, size: s), block: block)
   }

   private func size(for block: Block) -> CGSize {
      let width = (self.size.width + self.size.height) * 0.05
      let totalAmount = block.totalAmount

      let minWidth: CGFloat = width
      let maxWidth: CGFloat = width * 1.5

      let minB = visibleBlocks.min(by: { $0.totalAmount < $1.totalAmount })
      let maxB = visibleBlocks.max(by: { $0.totalAmount < $1.totalAmount })

      let minAmount1 = minB?.totalAmount ?? block.totalAmount
      let maxAmount1 = maxB?.totalAmount ?? block.totalAmount
      let minAmount2 = totalAmount < minAmount1 ? totalAmount : minAmount1
      let maxAmount2 = totalAmount > maxAmount1 ? totalAmount : maxAmount1

      let low1 = CGFloat(minAmount2)
      let high1 = CGFloat(maxAmount2)
      let low2 = minWidth
      let high2 = maxWidth

      let remaped = remap(value: CGFloat(totalAmount),
                          low1: low1, high1: high1,
                          low2: low2, high2: high2)
      let length = (low1 != high1) ? remaped : minWidth

      //print(totalAmount, low1, high1, low2, high2, remaped)
      let size = CGSize(width: length, height: length)
      return size
   }

   private func removeOffScreenNodes() {
      for child in children {
         if !frame.contains(child.frame) &&
            !frame.intersects(child.frame) &&
            child.name != nil {
               child.removeFromParent()
         }
      }
   }

   private var visibleBlocks: [Block] {
      return children.flatMap {
         guard let block = $0.userData?["block"] as? Block else {
            return nil
         }
         return block
      }
   }

   func random(_ range: Range<Int>) -> Int {
      return range.lowerBound + Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound)))
   }

   private func remap(value: CGFloat, low1: CGFloat, high1: CGFloat, low2: CGFloat, high2: CGFloat) -> CGFloat {
      let remaped = low2 + (value - low1) * (high2 - low2) / (high1 - low1)
      return remaped
   }

   override func update(_ currentTime: TimeInterval) {
      // Called before each frame is rendered
   }
}

