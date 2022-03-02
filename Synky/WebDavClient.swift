//
//  WebDavClient.swift
//  Synky
//
//  Created by Brandon Lyon on 3/1/22.
//

import Foundation
import WebDAV

public struct SimpleAccount: WebDAVAccount {
    public var username: String?
    public var baseURL: String?
}

private func baseURL (service : ServiceModel) -> String? {
    var host = service.host
    if host != nil {
        if !host!.starts(with: "http") {
            host = "https://\(host!)"
        }
    }
    return host
}

private func webdavErrorToString (_ error: WebDAVError) -> String {
    switch error {
    case .nsError(let nsError):
        return nsError.localizedDescription
    default:
        return error.localizedDescription
    }
}

class WebDavFileSynchronizerSource : FileSynchronizerSource {
    let rootNode: FileSynchronizerNode = SimpleFileSynchronizerNode(parent: nil, name: "", exists: true)
    
    var client: WebDavClient
    var path: String
    
    init(client: WebDavClient, path: String){
        self.client = client;
        self.path = path
    }
    
    func getChildren(_ node: FileSynchronizerNode) async throws -> [FileSynchronizerNode] {
        try await client.list(path: nodeToPath(node)).map { file in
            SimpleFileSynchronizerNode(parent: node, name: file.fileName, exists: true, isDirectory: file.isDirectory, modifiedTime: file.lastModified, size: Int64(file.size))
        }
    }
    
    func write(_ node: FileSynchronizerNode, data: Data) async throws {
        // TODO: Implement
        fatalError("TODO: Implement WebDavFileSynchronizerSource.write")
    }

    func read(_ node: FileSynchronizerNode) async throws -> Data {
        try await client.download(path: nodeToPath(node))
    }
    
    func delete(_ node: FileSynchronizerNode) async throws {
        // TODO: Implement
        fatalError("TODO: Implement WebDavFileSynchronizerSource.delete")
    }
    
    func createDirectory(_ node: FileSynchronizerNode) async throws {
        // TODO: Implement
        fatalError("TODO: Implement WebDavFileSynchronizerSource.createDirectory")
    }
    
    private func nodeToPath(_ node: FileSynchronizerNode) -> String {
        "\(path)\(node.path)"
    }
}

class WebDavClient : BasicServiceClient {
    let noCache : WebDAVCachingOptions = [.requestEvenIfCached, .doNotReturnCachedResult, .doNotCacheResult]
    let webdavAccount: SimpleAccount
    let webdav = WebDAV()
    
    override init(service : ServiceModel, account : AccountModel){
        self.webdavAccount = SimpleAccount(username: account.username, baseURL: baseURL(service: service))
        super.init(service: service, account: account)
    }
    
    override func test(after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult{
        var result = ServiceCallResult()
        if account.password == nil {
            error = "Account password is required"
            result.success = false
            result.error = error
            after(result)
        } else if webdavAccount.username == nil {
            error = "Account username is required"
            result.success = false
            result.error = error
            after(result)
        } else if webdavAccount.baseURL == nil {
            error = "Service host is required"
            result.success = false
            result.error = error
            after(result)
        } else {
            webdav.listFiles(atPath: "/", account: webdavAccount, password: account.password!, caching: noCache) { files, error in
                if error != nil {
                    self.error = webdavErrorToString(error!)
                    result.error = self.error
                    result.success = false
                } else {
                    result.success = true
                }
                after(result)
            }
        }
        return result
    }
    
    override func getFileSynchronizerSource(path: String) -> FileSynchronizerSource {
        return WebDavFileSynchronizerSource(client: self, path: path)
    }
    
    func download (path: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            webdav.download(fileAtPath: path, account: webdavAccount, password: account.password!) { data, error in
                if error == nil {
                    continuation.resume(returning: data!)
                } else {
                    continuation.resume(throwing: error.unsafelyUnwrapped)
                }
            }
        }
    }
    
    func list (path: String) async throws -> [WebDAVFile] {
        return try await withCheckedThrowingContinuation { continuation in
            webdav.listFiles(atPath: path, account: webdavAccount, password: account.password!, caching: noCache) { files, error in
                if error == nil {
                    continuation.resume(returning: files!)
                } else {
                    continuation.resume(throwing: error.unsafelyUnwrapped)
                }
            }
        }
    }
}
