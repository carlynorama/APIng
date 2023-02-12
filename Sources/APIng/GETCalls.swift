import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

fileprivate var session = URLSession.shared

public func serverHello(from url:URL) async throws {
    let (_, response) = try await session.data(from: url)  //TODO: catch the error here
    let httpResponse = response as! HTTPURLResponse
    if (200...299).contains(httpResponse.statusCode) {
        print("success, \(httpResponse.statusCode), \(String(describing:httpResponse.mimeType))")
    } else {
        print("Not in success range, \(httpResponse.statusCode), \(String(describing:httpResponse.mimeType))")
        //handleServerError(httpResponse)
    }

}  

public func getData(from url:URL) async throws -> Data {
    let (data, response) = try await session.data(from: url) 
    //What if it's not HTTP? 
    let httpResponse = response as! HTTPURLResponse
    guard (200...299).contains(httpResponse.statusCode) else {
        print("Not in success range, \(httpResponse.statusCode), \(String(describing:httpResponse.mimeType))")
        //handleServerError(httpResponse)
        throw APIngError("getData: No data")
    }
    return data
}

public func getRawString(from url:URL, encoding:String.Encoding = .utf8) async throws -> String {
    let (data, _) = try await session.data(from: url)
    guard let string = String(data: data, encoding: encoding) else {
        throw APIngError("Got data, couldn't make a string with \(encoding)")
    }
    return string
}

func getObject<T:Codable>(ofType:T.Type, fromURL url:URL) async -> T? {
    do {
        let result = try await getData(from: url).asValue(ofType: ofType)
        //print(result)
        return result
    } catch {
        print(error)
    }
    return nil
}

//MARK: Generic New Type of JSON printer
func getJSON(from url:URL) async -> String? {
    do {
        let result = try await getRawString(from: url, encoding: .utf8)
        print(result)
        return result
    } catch {
        print(error)
    }
    return nil
}

func getCollectionOfOptionals<SomeDecodable: Decodable>(ofType:SomeDecodable.Type, from url:URL) async throws -> [SomeDecodable?] {
    try await getData(from: url).asCollectionOfOptionals(ofType: ofType)
}

func getDictionary(from url:URL) async throws -> [String: Any]? {
    try await getData(from: url).asDictionary()
}

func getValue<SomeDecodable: Decodable>(ofType:SomeDecodable.Type, from url:URL, decoder:JSONDecoder = JSONDecoder()) async throws -> SomeDecodable {
    try await getData(from: url).asValue(ofType: ofType, decoder:decoder)
}

func getTransformedValue<SomeDecodable: Decodable, Transformed>(
    ofType: SomeDecodable.Type,
    from url:URL,
    transform: @escaping (SomeDecodable) throws -> Transformed
) async throws -> Transformed {
    try await getData(from: url).asTransformedValue(ofType: ofType, transform: transform)
}

func getOptional<SomeDecodable: Decodable>(ofType:SomeDecodable.Type, from url:URL, decoder:JSONDecoder = JSONDecoder()) async throws -> SomeDecodable? {
    try await getData(from: url).asOptional(ofType: ofType)
}

func getCollection<SomeDecodable: Decodable>(ofType:SomeDecodable.Type, from url:URL) async throws -> [SomeDecodable?] {
    try await getData(from: url).asCollection(ofType: ofType)
}