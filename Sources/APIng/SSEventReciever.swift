//
//  ServerSentEventListener.swift
//  
//
//  Created by Carlyn Maw on 2/17/23.
//
// In that case you need to use the URLSession delegate-based APIs (dataTask(with:) and so on), which will call the urlSession(_:dataTask:didReceive:) session delegate method with chunks of data as they arrive.
//https://stackoverflow.com/questions/44602192/how-to-use-urlsessionstreamtask-with-urlsession-for-chunked-encoding-transfer/75466620#75466620
//https://www.hackingwithswift.com/articles/241/how-to-fetch-remote-data-the-easy-way-with-url-lines
// "The right way"?:https://github.com/launchdarkly/swift-eventsource/blob/main/Source/LDSwiftEventSource.swift

//------------- SPEC
//https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation

//Streams must be decoded using the UTF-8 decode algorithm.
//
//The UTF-8 decode algorithm strips one leading UTF-8 Byte Order Mark (BOM), if any.
//
//The stream must then be parsed by reading everything line by line, with a U+000D CARRIAGE RETURN U+000A LINE FEED (CRLF) character pair, a single U+000A LINE FEED (LF) character not preceded by a U+000D CARRIAGE RETURN (CR) character, and a single U+000D CARRIAGE RETURN (CR) character not followed by a U+000A LINE FEED (LF) character being the ways in which a line can end.
//------------- \SPEC



import Foundation

public struct SSEStreamEvent:Hashable {
    public let lastEventId:String?
    public let message:String?
    public let data:String?
    public let sourceURL:URL  //resolve after redirects?
    public let withCredentials:Bool
    
    
    var description:String {
        "Event with lastID\(lastEventId ?? "") type:\(message ?? "") with \(data?.count ?? 0) bytes"
    }
}


//To return AsyncStream<[String:String]> see extension commented out below. 
public func getSSEStream(url:URL) async throws -> some AsyncSequence {
    // if streamService == nil { streamService = SSEListener(url: url) } else {
    //     //TODO: Build in the ability to handle more than one stream. In SSEListener or MastodonServer or combined.
    //     throw MastodonAPIError("Someone is already streaming...")
    // }
    let streamService = SSEListener(url: url)
    return streamService.eventStream().map { event in
            let mse: Dictionary<String, String> = [
                "type" : event.message ?? "undefined",
                    "data" : event.data ?? "empty"
                    ]
            return mse
        }
}

// https://forums.swift.org/t/when-can-we-move-asyncsequence-forward/61991/2
// extension AsyncStream {
//   init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
//     var iterator: S.AsyncIterator?
//     self.init {
//       if iterator == nil {
//         iterator = sequence.makeAsyncIterator()
//       }
//       return try? await iterator?.next()
//     }
//   }
// }




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

enum SSEListenerStatus {
    case open, connecting, closed
}

//This is a less useful because not using the original URLSession dataTask pattern to access the bytes.
public class SSEListener: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    private var urlRequest: URLRequest
    private var url:URL
    private var session: URLSession! = nil
    
    private var sessionDataTask:URLSessionDataTask?
    //private var sessionTask:URLSessionTask?
    private var task:Task<Void, Error>?
    
    private var eventStreamTask:Task<Void, Error>?
    
    //private var status:SSEListenerStatus = .closed
    //private var cancelled = true
    
    private var connectionTime:Date?
    private var refreshInterval:TimeInterval?
    
    
    //SPEC: When a stream is parsed, a data buffer, an event type buffer, and a last event ID buffer must be associated with it.
    //SPEC: They must be initialized to the empty string.
    private var infoBuffer:[String:String] = [
        //"last_event_ID":"",  //prefer this to be nil if not used.
        "data": "",
        "event_type": ""
    ]
    
    var isListening:Bool {
        sessionDataTask != nil
    }
    
    public init(url:URL, urlSession:URLSession? = nil) {
        //--------- SPEC
        //GET
        //Accept: text/event-stream
        //Cache-Control: no-cache
        //Connection: keep-alive
        //--------- \SPEC
        self.url = url
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300.0)
        request.setValue("text/event-stream", forHTTPHeaderField:"Accept")
        //request.setValue("no-cache", forHTTPHeaderField: "Cache-Control") //does this make a difference w/ Mastodon?
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
    

    //same as the task getting back from .bytes
//    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
//        print("I made a task:\(task)")
//        self.sessionTask = task
//    }
    
    //public func url

//Fires on termination.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        //print("got metrics, task \(task) took \(metrics.taskInterval)")
        print(metrics)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        print("redirecting... \(String(describing: request.url))")
        self.urlRequest = request
        self.url = request.url!
        return request
    }
    
    //doesn't fire b/c try in call?? because Task doesn't return it?
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("---------------- I HEARD IT \(String(describing: error))")
    }
    
    public func eventStream() ->  AsyncThrowingStream<SSEStreamEvent, Error> {
        makeEventStream()
    }
    
    
    private func makeEventStream() -> AsyncThrowingStream<SSEStreamEvent, Error> {
        return AsyncThrowingStream { continuation in
            if task != nil { task?.cancel() }
            task = Task {
                
                if sessionDataTask != nil { sessionDataTask?.cancel() }
                //status = .connecting
                let (asyncBytes, response) = try await self.session.bytes(for: self.urlRequest, delegate: self)

                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIngError("Not HTTP")
                }
                
               
                guard (200...299).contains(httpResponse.statusCode) else {
                    print(httpResponse.statusCode)
                    throw APIngError("\(httpResponse.statusCode)")
                }
                
                self.sessionDataTask = asyncBytes.task
                connectionTime = Date.now
                
                //var expectSSE = true

                //asyncBytes.lines ignores empty lines had to make my own
                var iterator = asyncBytes.allLines_v1.makeAsyncIterator()
                while let line = try await iterator.next() {
                    //status = .open
                    //print("line in loop: \(line)")
//                    if line.prefix(1) == "<" {
//                        print( "Not an SSE Line ")
//                        expectSSE = false
//                    }
//                    if expectSSE {
                        let decodedLine = try await SSELine(line)
                        let result = processSSELine(buffer: infoBuffer, line: decodedLine)
                        infoBuffer = result.buffer
                        if let sse = result.sse {
                            continuation.yield(sse)
                        }
                    //}
                    await affirmConnection()
                }
            }
            continuation.onTermination = { @Sendable _ in
                self.cancel()
            }
        }

        
    }
    
    private func affirmConnection() async {
        //let liveTasks = await session.tasks
        //print(sessionDataTask)
        //if liveTasks.0[0].
        
    }
    
    private func processSSELine(buffer:[String:String], line:SSELine) -> (buffer:[String:String], sse:SSEStreamEvent?) {
        var mBuffer = buffer
        switch line {
            case .event(let event_type):
                //SPEC: Set the event type buffer to field value.
                mBuffer["event_type"] = event_type
            case .data(let new_data):
                //print("data: \(new_data.count)")
                //SPEC: Append the field value to the data buffer, then append a single U+000A LINE FEED (LF) character to the data buffer.
                var currentData = ""
                if mBuffer["data"] != nil {
                    currentData.append(contentsOf: mBuffer["data"]!)
                }
                currentData.append(contentsOf: new_data)
                currentData.append("\u{000A}")
                mBuffer["data"] = currentData
            case .id(let id):
                //SPEC: set the last event ID buffer to the field value
                mBuffer["last_event_ID"] = id
            case .retry(let time):
                setReconnectionTime(time)
            case .ignore:
                break
            case .comment(let message):
                print("stream comment: \(message)") //should maybe just ignore, but want to give option of retaining comment.
                break
            case .dispatch:
                if let sse = makeSSEStreamEvent(tryWith: mBuffer) {
                    //print(sse)
                    mBuffer["data"] = ""
                    mBuffer["event_type"] = ""
                    //continuation.yield(sse)
                    return (mBuffer, sse)
                } else { print("something went wrong")}
                mBuffer["data"] = ""
                mBuffer["event_type"] = ""
        }
        return (mBuffer, nil)
    }
    
    
    func makeSSEStreamEvent(tryWith tmp:[String:String]) -> SSEStreamEvent? {
        //print(tmp)
        if tmp.isEmpty { return nil }
        if tmp.allSatisfy({ $1.isEmpty }) { return nil }
        var eventBuilder = tmp
        if var data:String = eventBuilder["data"] {
            if data.isEmpty { eventBuilder["event_type"] = "" }
            if data.last == "\u{000A}" {  _ = data.popLast() }
        }
        return (SSEStreamEvent(
            lastEventId: eventBuilder["last_event_ID"],
            message: eventBuilder["event_type"],
            data: eventBuilder["data"],
            sourceURL:urlRequest.url!,
            withCredentials:false)
        )
    }
    //set the event stream's reconnection time to that integer
    func setReconnectionTime(_ time:Int) {
        print("do something with this \(time)")
    }
    
    func watchStream(handler:@escaping (SSEStreamEvent)->Void) async throws {
        for try await event in eventStream() {
            handler(event)
        }
    }
    
    public func stopListening() throws {
        //self.cancelled = true
        self.cancel()
    }
    
    private func cancel() {
        //status = .closed
        sessionDataTask?.cancel()
        task?.cancel()
        sessionDataTask = nil
    }
    
    
    enum SSELine {
        case event(String), data(String), id(String), retry(Int), ignore, comment(String), dispatch
        
        init(_ candidateString:String) async throws {
            //print(candidateString)
            
            //SPEC: If the line is empty (a blank line) Dispatch the event
            if candidateString.isEmpty { self = Self.dispatch; return }
            
            //SPEC: If the line starts with a U+003A COLON character (:) Ignore the line.
            if candidateString.prefix(1) == ":" {
                var message = candidateString
                message.removeFirst()
                self = Self.comment(message); return
            }
            
            //SPEC: If the line contains a U+003A COLON character (:)
            //SPEC: Collect the characters on the line before the first U+003A COLON character (:), and let field be that string. Collect the characters on the line after the first U+003A COLON character (:), and let value be that string.
            var splitResult = candidateString.split(separator: ":", maxSplits: 1).map(String.init)
            
            
            guard splitResult.count == 2 else {
                print("SSELine init couldn't make proper split from:\(candidateString)")
                self = Self.ignore; return
            }
            
            //SPEC: If value starts with a U+0020 SPACE character, remove it from value.
            //" ", ASCII 32, does seem to work, but might as well be explicit.
            if splitResult[1].prefix(1) == "\u{0020}" {
                //splitResult[1] = String(splitResult[1].trimmingPrefix(while: \.isWhitespace))
                splitResult[1] = String(splitResult[1].trimmingPrefix(while: {$0 == "\u{0020}"}))
            }
            
            switch splitResult[0] {
            case "event":
                self = Self.event(splitResult[1])
            case "data":
                self = Self.data(splitResult[1])
            case "retry":
                //SPEC: If the field value consists of only ASCII digits, then interpret the field value as an integer in base ten, and set the event stream's reconnection time to that integer. Otherwise, ignore the field.
                if let value = Int(splitResult[1]) { self = Self.retry(value) }
                else { self = Self.ignore }
            case "id":
                //SPEC: If the field value does not contain U+0000 NULL, then set the last event ID buffer to the field value. Otherwise, ignore the field.
                if !splitResult[1].contains("\u{0000}") { self = Self.id(splitResult[1]) }
                else { self = Self.ignore }
            default:
                self = Self.ignore
            }
        }
    }
    

}

extension AsyncSequence where Element == UInt8 {
    //Works.
    //TODO: https://github.com/apple/swift-async-algorithms/blob/ed0b086089f4e9ac76b3cb6138f578c25e661f34/Sources/AsyncAlgorithms/AsyncBufferedByteIterator.swift
    var allLines_v1:AsyncThrowingStream<String, Error> {
        
        AsyncThrowingStream { continuation in
            //with a U+000D CARRIAGE RETURN U+000A LINE FEED (CRLF) character pair, a single U+000A LINE FEED (LF) character not preceded by a U+000D CARRIAGE RETURN (CR) character, and a single U+000D CARRIAGE RETURN (CR) character not followed by a U+000A LINE FEED (LF) character being the ways in which a line can end.
            //let lineBreaks:[UInt8] = [13,10] //U+000D CARRIAGE RETURN, U+000A LINE FEED (LF)
            let bytesTask = Task {
                var accumulator:[UInt8] = []
                var iterator = self.makeAsyncIterator()
                var CRFlag = false
                while let byte = try await iterator.next() {
                    if CRFlag || byte == 10 {
                        if accumulator.isEmpty { continuation.yield("") }
                        else {
                            if let line = String(data: Data(accumulator), encoding: .utf8) { continuation.yield(line) }
                            else { throw APIngError("allLines: Couldn't make string from [UInt8] chunk") }
                            accumulator = []
                        }
                    } else {
                        accumulator.append(byte)
                    }
                    CRFlag = (byte == 13)
            }   }
            continuation.onTermination = { @Sendable _ in
                bytesTask.cancel()
    }   }   }
    
    //This code... looses bytes? Looses every-other packet somehow?
    //Something isn't right with the accumulator.
    //setting it to [] or not doesn't seem to make a difference, and it should?
//    var allLines_v2:AsyncThrowingStream<String, Error> {
//        return AsyncThrowingStream {
//            var accumulator:[UInt8] = []
//            for try await byte in self {
//                //10 == \n
//                if byte != 10 { accumulator.append(byte) }
//                else {
//                    if accumulator.isEmpty { return "" }
//                    else {
//                        //print(String(data: Data(accumulator), encoding: .utf8))
//                        if let line = String(data: Data(accumulator), encoding: .utf8) {
//                            //accumulator = [];
//                            print("allLines_v2: \(line)")
//                            return line
//                        }
//                        else {
//                            //accumulator = [];
//                            throw APIngError("allLines: Couldn't make string from [UInt8] chunk") }
//             }    }   }
//            return nil
//        }
//    }
}


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