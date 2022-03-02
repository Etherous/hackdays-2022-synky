//
//  ServiceClient.swift
//  Synky
//
//  Created by Brandon Lyon on 3/1/22.
//

import NetworkExtension
import SystemConfiguration.CaptiveNetwork

func createServiceClient(service: ServiceModel, account: AccountModel) -> ServiceClient? {
    if service.type == nil {
        return nil
    }
    switch ServiceType.find(service.type!)! {
    case .none:
        return nil
    case .webdav:
        return WebDavClient(service: service, account: account)
    case .ftp:
        return FtpClient(service: service, account: account)
    }
}

struct ServiceCallResult {
    var success: Bool? = nil
    var error: String? = nil
}

protocol ServiceClient {
    func test(after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult
    func runSchedule(_ schedule: ScheduleModel, isForced: Bool, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult
    func upload(from: URL, to: String, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult
    func download(from: String, to: URL, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult
    func biDirectionalSync(local: URL, remote: String, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult
    var error: String? {get}
}

class ServiceClientFileSynchronizer : FileSynchronizer {
    var result: ServiceCallResult
    
    var after: (ServiceCallResult) -> Void
    
    init(_ sourceA: FileSynchronizerSource, _ sourceB: FileSynchronizerSource, bidirectional: Bool = false, result: ServiceCallResult, after: @escaping (ServiceCallResult) -> Void){
        self.result = result
        self.after = after
        super.init(sourceA, sourceB, bidirectional: bidirectional)
    }
}

class BasicServiceClient : ServiceClient {
    let service : ServiceModel
    
    let account : AccountModel
    
    var error : String?
    
    init(service : ServiceModel, account : AccountModel){
        self.service = service
        self.account = account
    }
    
    func test(after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult {
        let error = "Not implemented"
        self.error = error
        let result = ServiceCallResult(success: false, error: error)
        after(result)
        return result
    }
    
    func runSchedule(_ schedule: ScheduleModel, isForced: Bool, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult {
        var result = ServiceCallResult()
        if !isForced && isCellular() {
            result.success = true
        } else if schedule.localPath == nil {
            error = "Local path is required"
            result.success = false
            result.error = error
        } else if schedule.remotePath == nil {
            error = "Remote path is required"
            result.success = false
            result.error = error
        } else {
            switch SyncDirection.find(schedule.direction!)! {
            case .up:
                return upload(from: schedule.localPath!, to: schedule.remotePath!, after: after)
            case .down:
                return download(from: schedule.remotePath!, to: schedule.localPath!, after: after)
            case .bi:
                return biDirectionalSync(local: schedule.localPath!, remote: schedule.remotePath!, after: after)
            }
        }
        after(result)
        return result
    }
    
    func upload(from: URL, to: String, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult {
        let result = ServiceCallResult()
        ServiceClientFileSynchronizer(LocalFileSynchronizerSource(url: from), getFileSynchronizerSource(path: to), bidirectional: false, result: result, after: after)
            .run()
        return result
    }
    
    func download(from: String, to: URL, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult {
        let result = ServiceCallResult()
        ServiceClientFileSynchronizer(getFileSynchronizerSource(path: from), LocalFileSynchronizerSource(url: to), bidirectional: false, result: result, after: after)
            .run()
        return result
    }

    func biDirectionalSync(local: URL, remote: String, after: @escaping (ServiceCallResult) -> Void) -> ServiceCallResult {
        let result = ServiceCallResult()
        ServiceClientFileSynchronizer(LocalFileSynchronizerSource(url: local), getFileSynchronizerSource(path: remote), bidirectional: true, result: result, after: after)
            .run()
        return result
    }
    
    func getFileSynchronizerSource(path: String) -> FileSynchronizerSource {
        fatalError("BasicServiceClient.getFileSynchronizerSource has not been implemented")
    }

    private func isCellular() -> Bool {
        return getSSID() == nil
    }
    
    private func getSSID() -> String? {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    return interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                }
            }
        }
        return nil
    }
}
