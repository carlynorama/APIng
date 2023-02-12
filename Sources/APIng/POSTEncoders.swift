import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func makeURLEncodedString(formItems:Dictionary<String, CustomStringConvertible>) throws -> String {
    var urlQueryItems:[URLQueryItem] = []
    for (key, value) in formItems {
        urlQueryItems.append(URLQueryItem(name:key, value:String(describing:value)))
    }
    return try makeURLEncodedString(queryItems:urlQueryItems)
}

func makeURLEncodedString(queryItems:[URLQueryItem]) throws -> String {
    let pieces = queryItems.map(urlEncode)
    let bodyString = pieces.joined(separator: "&")
    return bodyString
}

private func urlEncode(_ queryItem: URLQueryItem) -> String {
    let name = urlEncode(queryItem.name)
    let value = urlEncode(queryItem.value ?? "")
    return "\(name)=\(value)"
}

private func urlEncode(_ string: String) -> String {
    let allowedCharacters = CharacterSet.alphanumerics
    return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
}