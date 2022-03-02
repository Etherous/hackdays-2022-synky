//
//  FileSynchronizer.swift
//  Synky
//
//  Created by Brandon Lyon on 3/1/22.
//

import Foundation
import UIKit
import Collections

protocol FileSynchronizerNode {
    var pathSeparator: Character {get}
    var parent: FileSynchronizerNode? {get}
    var name: String {get}
    var path: String {get}
    var exists: Bool {get}
    var isDirectory: Bool? {get}
    var modifiedTime: Date? {get}
    var size: Int64? {get}
}

struct SimpleFileSynchronizerNode : FileSynchronizerNode{
    let parent: FileSynchronizerNode?
    let name: String
    let exists: Bool
    let pathSeparator: Character
    let path: String
    var isDirectory: Bool?
    var modifiedTime: Date?
    var size: Int64?
    
    init(parent: FileSynchronizerNode?, name: String, exists: Bool) {
        self.parent = parent
        self.name = name
        self.exists = exists
        pathSeparator = parent?.pathSeparator ?? "/"
        path = parent != nil ? "\(parent!.path)\(pathSeparator)\(name)" : name
    }
    
    init(parent: FileSynchronizerNode?, name: String, exists: Bool, isDirectory: Bool, modifiedTime: Date, size: Int64) {
        self.init(parent: parent, name: name, exists: exists)
        self.isDirectory = isDirectory
        self.modifiedTime = modifiedTime
        self.size = size
    }
}

protocol FileSynchronizerSource {
    var rootNode: FileSynchronizerNode {get}
    
    func getChildren(_ node: FileSynchronizerNode) async throws -> [FileSynchronizerNode]
    func write(_ node: FileSynchronizerNode, data: Data) async throws
    func read(_ node: FileSynchronizerNode) async throws -> Data
    func delete(_ node: FileSynchronizerNode) async throws
    func createDirectory(_ node: FileSynchronizerNode) async throws
}

class LocalFileSynchronizerSource : FileSynchronizerSource {
    let rootNode: FileSynchronizerNode = SimpleFileSynchronizerNode(parent: nil, name: "", exists: true)
    let fileManager = FileManager.default
    
    var url : URL
    
    init(url: URL){
        self.url = url
    }
    
    func getChildren(_ node: FileSynchronizerNode) async throws -> [FileSynchronizerNode] {
        let urls = try fileManager.contentsOfDirectory(at: getUrlForNode(node), includingPropertiesForKeys: nil, options: [])
        print(urls)
        return urls.map {url in SimpleFileSynchronizerNode(parent: node, name: url.lastPathComponent, exists: true)}
    }
    
    func write(_ node: FileSynchronizerNode, data: Data) async throws {
        // TODO: Implement
        fatalError("TODO: Implement LocalFileSynchronizerSource.write")
    }
    
    func read(_ node: FileSynchronizerNode) async throws -> Data {
        return try Data(contentsOf: getUrlForNode(node))
    }
    
    func delete(_ node: FileSynchronizerNode) async throws {
        // TODO: Implement
        fatalError("TODO: Implement LocalFileSynchronizerSource.delete")
    }
    
    func createDirectory(_ node: FileSynchronizerNode) async throws {
        // TODO: Implement
        fatalError("TODO: Implement LocalFileSynchronizerSource.createDirectory")
    }
    
    func getUrlForNode(_ node : FileSynchronizerNode) -> URL {
        print("Appending \(node.path) to \(url)")
        let result = url.appendingPathExtension(node.path)
        print(result)
        return result
    }
}

class FileSynchronizer {
    var fromSource : FileSynchronizerSource
    var toSource : FileSynchronizerSource
    let bidirectional : Bool
    
    init(_ fromSource: FileSynchronizerSource, _ toSource: FileSynchronizerSource, bidirectional: Bool = false){
        self.fromSource = fromSource
        self.toSource = toSource
        self.bidirectional = bidirectional
    }
    
    func run() {
        Task(priority: .medium) {
            var scanning: Deque<(FileSynchronizerNode,FileSynchronizerNode)> = []
            var transferring: Deque<(FileSynchronizerNode,FileSynchronizerNode)> = []
            scanning.append((fromSource.rootNode, toSource.rootNode))
            
            // Scan full directory tree
            while !scanning.isEmpty {
                let pair = scanning.popFirst()!
                do {
                    let fromChildren = try await fromSource.getChildren(pair.0)
                    let toChildren = try await toSource.getChildren(pair.1)
                    let toChildrenByName = toChildren.reduce(into: [String: FileSynchronizerNode]()) { $0[$1.name] = $1 }
                    for fromChild in fromChildren {
                        if !fromChild.exists {
                            continue
                        }
                        var toChild = toChildrenByName[fromChild.name]
                        if toChild != nil && toChild!.exists {
                            if fromChild.isDirectory! != toChild!.isDirectory! {
                                // Delete remote file if file vs directory differs
                                try await toSource.delete(toChild!)
                                // TODO: Increment delete count
                                toChild = nil
                            } else {
                                // Skip if size and modified time match
                                if fromChild.isDirectory! || (fromChild.size == toChild!.size && fromChild.modifiedTime == toChild!.modifiedTime) {
                                    // TODO: Increment skip count
                                    continue
                                }
                            }
                        }
                        toChild = toChild ?? SimpleFileSynchronizerNode(parent: pair.1, name: fromChild.name, exists: false)
                        if fromChild.isDirectory! {
                            // Create directory
                            // TODO: Increment created directory count
                            try await toSource.createDirectory(toChild!)
                            
                            // Add child directory to queue
                            scanning.append((fromChild,toChild!))
                        } else {
                            // File will be transferred
                            // TODO: Increment total transfer count
                            // TODO: Add total transfer size
                            transferring.append((fromChild,toChild!))
                        }
                    }
                } catch {
                    print("Error occurred while scanning \(pair.0) -> \(pair.1)")
                }
            }
            
            // TODO: Start transfer timer
            // Transfer all files
            while(!transferring.isEmpty) {
                let pair = scanning.popFirst()!
                let fromChild = pair.0
                let toChild = pair.1
                do {
                    try await toSource.write(toChild, data: fromSource.read(fromChild))
                } catch {
                    print("Error occurred during transfer")
                }
                // TODO: Add completed transfer size
                // TODO: Increment completed transfer count
            }
            // TODO: Stop transfer timer. Calculate bandwidth
        }
    }
}
