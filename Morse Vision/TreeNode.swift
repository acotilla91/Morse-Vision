//
//  TreeNode.swift
//  Morse Vision
//
//  Created by Alejandro Cotilla on 9/19/18.
//  Copyright © 2018 Alejandro Cotilla. All rights reserved.
//

import UIKit

// Tree data structure based on: https://www.raywenderlich.com/1053-swift-algorithm-club-swift-tree-data-structure
class TreeNode {
    var value: String
    private(set) var children: [TreeNode] = []
    private(set) weak var parent: TreeNode?
    
    init(_ value: String) {
        self.value = value
    }
    
    func add(child: TreeNode) {
        children.append(child)
        child.parent = self
    }
    
    func addChild(value: String) -> TreeNode {
        let node = TreeNode(value)
        add(child: node)
        return node
    }
    
    func leftChild() -> TreeNode? {
        return children[safe: 0]
    }
    
    func rightChild() -> TreeNode? {
        return children[safe: 1]
    }
    
    // Morse code tree based on: https://commons.wikimedia.org/wiki/File:Morse-code-tree.svg
    static var morseTree: TreeNode = {
        let morseTree = TreeNode("root")
        
        // Level 1
        let eNode = morseTree.addChild(value: "E")
        let tNode = morseTree.addChild(value: "T")
        
        // Level 2
        let iNode = eNode.addChild(value: "I")
        let aNode = eNode.addChild(value: "A")
        let nNode = tNode.addChild(value: "N")
        let mNode = tNode.addChild(value: "M")
        
        // Level 3 (Left)
        let sNode = iNode.addChild(value: "S")
        let uNode = iNode.addChild(value: "U")
        let rNode = aNode.addChild(value: "R")
        let wNode = aNode.addChild(value: "W")
        
        // Level 3 (Right)
        let dNode = nNode.addChild(value: "D")
        let kNode = nNode.addChild(value: "K")
        let gNode = mNode.addChild(value: "G")
        _ = mNode.addChild(value: "O")
        
        // Level 4 (Left)
        _ = sNode.addChild(value: "H")
        _ = sNode.addChild(value: "V")
        _ = uNode.addChild(value: "F")
        _ = rNode.addChild(value: "L")
        _ = wNode.addChild(value: "P")
        _ = wNode.addChild(value: "J")
        
        // Level 4 (Right)
        _ = dNode.addChild(value: "B")
        _ = dNode.addChild(value: "X")
        _ = kNode.addChild(value: "C")
        _ = kNode.addChild(value: "Y")
        _ = gNode.addChild(value: "Z")
        _ = gNode.addChild(value: "Q")
        
        return morseTree
    }()
}

// Source: https://stackoverflow.com/a/30593673/1792699
extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
