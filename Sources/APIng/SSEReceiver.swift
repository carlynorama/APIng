import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

//Use async/await with URLSession WWDC21 session
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

class StreamPacketParser {
    enum PacketType {
        case eventLabel(label:String), data(json:String), thump
    }
    //will need swift collections
    private var buffer:Dequeue[string]
}
