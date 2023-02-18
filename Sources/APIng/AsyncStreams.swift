//
//  File.swift
//  
//
//  Created by Carlyn Maw on 2/17/23.
//
// In that case you need to use the URLSession delegate-based APIs (dataTask(with:) and so on), which will call the urlSession(_:dataTask:didReceive:) session delegate method with chunks of data as they arrive.
//https://stackoverflow.com/questions/44602192/how-to-use-urlsessionstreamtask-with-urlsession-for-chunked-encoding-transfer/75466620#75466620


import Foundation

public struct SSEStreamingEvent:Hashable {
    public let type:String
    public let data:Data
    
    var description:String {
        "Event of type:\(type) with \(data.count) bytes"
    }
}

enum SSEListenerError: Error, CustomStringConvertible {
    case message(String)
    public var description: String {
        switch self {
        case let .message(message): return message
        }
    }
    init(_ message: String) {
        self = .message(message)
    }
}

public class SSEListener: NSObject, URLSessionDataDelegate {
    private var urlRequest: URLRequest
    private var session: URLSession! = nil
    
    //var eventHandler:(SSEStreamEvent)->Void
    
    //public private(set) var accumulator:[SSEStreamEvent] = []
    private var dataTask:URLSessionDataTask?
    private var task:Task<Void, Error>?
    private var isListening:Bool = false
    
    //    var url:URL {
    //        urlRequest.url
    //    }
    
    public init(url:URL, urlSession:URLSession? = nil) {
        //we want
        //GET
        //Accept: text/event-stream
        //Cache-Control: no-cache
        //Connection: keep-alive
        var request = URLRequest(url: url,cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("text/event-stream", forHTTPHeaderField:"Accept")
        //confirm that keep-alive & no cache are true
        self.urlRequest = request
        
        super.init()
        if urlSession != nil {
            self.session = urlSession!
        } else {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        }
    }
    
    deinit {
        self.cancel()
    }
    
    // public func eventStream() -> AsyncThrowingStream<SSEStreamingEvent, Error> {
    //     return AsyncThrowingStream {
    //         let (asyncBytes, _) = try await self.session.bytes(for: self.urlRequest)
    //         self.dataTask = asyncBytes.task
            
    //         var iterator = asyncBytes.lines.makeAsyncIterator()
    //         while let line = try await iterator.next() {
    //             if !line.contains(":thump") && !(line == ":)") {
    //                 let decodedLine = try await SSELine(line)
    //                 if decodedLine.label == "event" {
    //                     guard let dataLine = try await iterator.next() else {
    //                         throw APIngError("openSSEStream never got a next line")
    //                     }
    //                     let dataEvent = try await SSELine(dataLine)
    //                     if dataEvent.label == "data" {
    //                         let event = SSEStreamingEvent(type:String(data:decodedLine.content, encoding:.utf8)!, data: dataEvent.content)
                            
    //                         return event
    //                         //accumulator.append(event)
    //                         //print(accumulator.count, accumulator.last?.description ?? "", Date.now)
    //                     } else { print("unexpected not data \(line)") }
    //                 } else {
    //                     print("unkown event \(line)")
    //                 }
                    
    //             }
                
    //         }
    //         return
    //     }
    // }
    
//    public func startListening() throws  {
//        print(dataTask ?? "no task")
//        task = Task { try await openSSEStream() }
//        // try await task?.value
//    }
    
    public func stopListening() throws {
        self.cancel()
    }
    
    private func cancel() {
        dataTask?.cancel()
        task?.cancel()
        dataTask = nil
    }
    
    struct SSELine:Codable {
        let label:String
        let content:Data
        
        init(_ candidateString:String) async throws {
            //print(candidateString)
            let splitResult = candidateString.split(separator: ":", maxSplits: 1).map(String.init)
            guard splitResult.count == 2 else {
                //print(candidateString)
                throw APIngError("SSELine init couldn't make proper split from:\(candidateString)")
            }
            self.label = splitResult[0]
            guard let data = splitResult[1].data(using: .utf8) else {
                print(candidateString)
                throw APIngError("SSELine init couldn't make data from string")
            }
            self.content = data
        }
    }
    
//    private func openSSEStream() async throws {
//        let (asyncBytes, _) = try await session.bytes(for: urlRequest)
//        dataTask = asyncBytes.task
//
//        var iterator = asyncBytes.lines.makeAsyncIterator()
//        while let line = try await iterator.next() {
//            if !line.contains(":thump") && !(line == ":)") {
//                let decodedLine = try await SSELine(line)
//                if decodedLine.label == "event" {
//                    guard let dataLine = try await iterator.next() else {
//                        throw MastodonAPIError("openSSEStream never got a next line")
//                    }
//                    let dataEvent = try await SSELine(dataLine)
//                    if dataEvent.label == "data" {
//                        let event = SSEStreamEvent(type:String(data:decodedLine.content, encoding:.utf8)!, data: dataEvent.content)
//                        accumulator.append(event)
//                        print(accumulator.count, accumulator.last?.description ?? "", Date.now)
//                    } else { print("unexpected not data \(line)") }
//                } else {
//                    print("unkown event \(line)")
//                }
//
//            }}
//    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        //NSLog("task data: %@", data as NSData)
        print("task data: %@", data as NSData)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            //NSLog("task error: %@ / %d", error.domain, error.code)
            print("task error: %@ / %d", error.domain, error.code)
        } else {
            print("task complete")
            //NSLog("task complete")
        }
    }
}



//
//
//public class SSEListener: NSObject, URLSessionDataDelegate {
//    private var urlRequest: URLRequest
//    private var session: URLSession! = nil
//
//    var eventHandler:(SSEStreamEvent)->Void
//
//    public private(set) var accumulator:[SSEStreamEvent] = []
//    private var dataTask:URLSessionDataTask?
//    private var task:Task<Void, Error>?
//    private var isListening:Bool = false
//
//    //    var url:URL {
//    //        urlRequest.url
//    //    }
//
//    public init(url:URL, urlSession:URLSession? = nil, handler: @escaping (SSEStreamEvent)->Void) {
//        //we want
//        //GET
//        //Accept: text/event-stream
//        //Cache-Control: no-cache
//        //Connection: keep-alive
//        var request = URLRequest(url: url,cachePolicy: .reloadIgnoringLocalCacheData)
//        request.setValue("text/event-stream", forHTTPHeaderField:"Accept")
//        //confirm that keep-alive & no cache are true
//        self.urlRequest = request
//
//        self.eventHandler = handler
//
//        super.init()
//        if urlSession != nil {
//            self.session = urlSession!
//        } else {
//            let config = URLSessionConfiguration.default
//            config.requestCachePolicy = .reloadIgnoringLocalCacheData
//            self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
//        }
//    }
//
//    deinit {
//        self.cancel()
//    }
//
//    public func eventStream() -> AsyncThrowingStream<SSEStreamEvent, Error> {
//        return AsyncThrowingStream { continuation in
//
//        }
//    }
//
//    public func startListening() throws  {
//        print(dataTask ?? "no task")
//        task = Task { try await openSSEStream() }
//        // try await task?.value
//    }
//
//    public func stopListening() throws {
//        self.cancel()
//    }
//
//    private func cancel() {
//        dataTask?.cancel()
//        task?.cancel()
//        dataTask = nil
//    }
//
//    struct SSELine:Codable {
//        let label:String
//        let content:Data
//
//        init(_ candidateString:String) async throws {
//            //print(candidateString)
//            let splitResult = candidateString.split(separator: ":", maxSplits: 1).map(String.init)
//            guard splitResult.count == 2 else {
//                //print(candidateString)
//                throw MastodonAPIError("SSELine init couldn't make proper split from:\(candidateString)")
//            }
//            self.label = splitResult[0]
//            guard let data = splitResult[1].data(using: .utf8) else {
//                print(candidateString)
//                throw MastodonAPIError("SSELine init couldn't make data from string")
//            }
//            self.content = data
//        }
//    }
//
//    private func openSSEStream() async throws {
//        let (asyncBytes, _) = try await session.bytes(for: urlRequest)
//        dataTask = asyncBytes.task
//
//        var eventLabel:SSELine? = nil
//
//        for try await line in asyncBytes.lines {
//            if !line.contains(":thump") && !(line == ":)") {
//                let decodedLine = try await SSELine(line)
//
//                switch decodedLine.label {
//                case "event":
//                    eventLabel = decodedLine
//                case "data":
//                    guard let thisLabel = eventLabel else { throw MastodonAPIError("SSEStreamListener: No label for data") }
//                    let event = SSEStreamEvent(type:String(data:thisLabel.content, encoding:.utf8)!, data: decodedLine.content)
//
//
//
//                    accumulator.append(event)
//                    eventHandler(event)
//
//                    eventLabel = nil
//                    print(accumulator.count, accumulator.last?.description ?? "", Date.now)
//
//                default:
//                    eventLabel = nil
//                }
//
//            }
//            else { eventLabel = nil }
//        }
//    }
//
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        //NSLog("task data: %@", data as NSData)
//        print("task data: %@", data as NSData)
//    }
//
//    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error as NSError? {
//            //NSLog("task error: %@ / %d", error.domain, error.code)
//            print("task error: %@ / %d", error.domain, error.code)
//        } else {
//            print("task complete")
//            //NSLog("task complete")
//        }
//    }
//}

// /// Returns dequoted string if receiver contains **quoted-string**
//     ///
//     /// - returns: dequoted string or `nil` if receiver does not contain valid quoted string
//     func dequotedString() -> String? {
//         guard !isEmpty else {
//             return nil
//         }
//         var resultView = String.UnicodeScalarView()
//         resultView.reserveCapacity(self.count)
//         var idx = startIndex
//         // Expect and consume dquote
//         guard self[idx] == _Delimiters.DoubleQuote else {
//             return nil
//         }
//         idx = self.index(after: idx)
//         var isQuotedPair = false
//         while idx < endIndex {
//             let currentScalar = self[idx]
//             if currentScalar == _Delimiters.Backslash && !isQuotedPair {
//                 isQuotedPair = true
//             } else if isQuotedPair {
//                 guard currentScalar.isQuotedPairEscapee else {
//                     return nil
//                 }
//                 isQuotedPair = false
//                 resultView.append(currentScalar)
//             } else if currentScalar == _Delimiters.DoubleQuote {
//                 break
//             } else {
//                 guard currentScalar.isQdtext else {
//                     return nil
//                 }
//                 resultView.append(currentScalar)
//             }
//             idx = self.index(after: idx)
//         }
//         // Expect stop on dquote
//         guard idx < endIndex, self[idx] == _Delimiters.DoubleQuote else {
//             return nil
//         }
//         return String(resultView)
//     }