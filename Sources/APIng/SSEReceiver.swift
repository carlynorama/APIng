import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

//Based on "Use async/await with URLSession" WWDC21 session

//Tested. 

// Do not appear to need do `URLRequest(url:url).setValue("text/event-stream", forHTTPHeaderField:"Accept")` manually. 
func streamReceiverTest(streamURL:URL, session:URLSession)  async throws {
    let (bytes, response) = try await session.bytes(from:streamURL)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIngError("Not an HTTPResponse")
    } 
    guard httpResponse.statusCode == 200 else {
        throw APIngError("Not a success: \(httpResponse.statusCode)")
    }

    for try await line in bytes.lines {
        print(line)
        print()
    }
}



func cancellableStreamReceiverTest(streamURL:URL, session:URLSession)  async throws {
    let (bytes, response) = try await session.bytes(from:streamURL)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIngError("Not an HTTPResponse")
    } 
    guard httpResponse.statusCode == 200 else {
        throw APIngError("Not a success: \(httpResponse.statusCode)")
    }

    for try await line in bytes.lines {
        try Task.checkCancellation()
        print(line)
        print()
    }
}

//https://httpbin.org/get

//Untested. 
func streamReceiver<LinePacketType:Decodable>(streamURL:URL, session:URLSession, ofType:LinePacketType.Type, packetHandler:@escaping (LinePacketType) async -> Void) async throws {

    let (bytes, response) = try await session.bytes(from:streamURL)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIngError("Not an HTTPResponse")
    } 
    guard httpResponse.statusCode == 200 else {
        throw APIngError("Not a success: \(httpResponse.statusCode)")
    }

    for try await line in bytes.lines {
        let linePacket = try JSONDecoder().decode(LinePacketType.self, from:Data(line.utf8))
        await packetHandler(linePacket)
    }
}



//More based on "Use async/await with URLSession" WWDC21 session
// Compiles but is untested. 
//------------------------
 
func sync(host:String, endpoint:Endpoint, session:URLSession, dataHandler:@escaping (Data) async -> Void) async throws {
  let request = URLRequest(url: try urlFromEndpoint(host: host, endpoint: endpoint))
  //The delegate is not an instance variable. It is strongly held by the task until the task completes or fails. 
  //The delegate can be used to handle events that are specific to THIS task only. 
  let (data, response) = try await session.data(for: request, delegate: AuthenticationDelegate(signInController: SignInController()))

  guard let httpResponse = response as? HTTPURLResponse else {
      throw APIngError("Not an HTTPResponse")
  } 
  guard httpResponse.statusCode == 200 else {
      throw APIngError("Not a success: \(httpResponse.statusCode)")
  }

  await dataHandler(data)
}

class SignInController {
    public func promptForCredential() async throws -> (username:String, password:String) {
        return (username:"hello", password:"world")
    }
}

class AuthenticationDelegate: NSObject, URLSessionTaskDelegate {
  private let signInController: SignInController
  
  init(signInController: SignInController) {
    self.signInController = signInController
  }
  
  func urlSession(
  	_ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge
  ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
      do {
        let (username, password) = try await signInController.promptForCredential()
        return (.useCredential, URLCredential(user: username, password: password, persistence: .forSession))
      } catch {
        return (.cancelAuthenticationChallenge, nil)
      }
    } else {
      return (.performDefaultHandling, nil)
    }
  }
}

func streamReceiverTestWithManualHeader(streamURL:URL, session:URLSession)  async throws {
    var request = URLRequest(url:streamURL)
    request.setValue("text/event-stream", forHTTPHeaderField:"Accept") 
    let (bytes, response) = try await session.bytes(for:request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIngError("Not an HTTPResponse")
    } 
    guard httpResponse.statusCode == 200 else {
        throw APIngError("Not a success: \(httpResponse.statusCode)")
    }

    for try await line in bytes.lines {
        print(line)
        print()
    }
}




// class StreamPacketParser {
//     enum PacketType {
//         case eventLabel(label:String), data(json:String), thump
//     }
//     //will need swift collections
//     private var buffer:Dequeue[string]
// }


// func getAverageTemperature() async {
//     let fetchTask = Task { () -> Double in
//         let url = URL(string: "https://hws.dev/readings.json")!
//         let (data, _) = try await URLSession.shared.data(from: url)
//         let readings = try JSONDecoder().decode([Double].self, from: data)
//         let sum = readings.reduce(0, +)
//         return sum / Double(readings.count)
//     }

//     do {
//         let result = try await fetchTask.value
//         print("Average temperature: \(result)")
//     } catch {
//         print("Failed to get data.")
//     }
// }

// await getAverageTemperature()