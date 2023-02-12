import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
    
    public init(path: String, queryItems: [URLQueryItem]) {
        self.path = path
        self.queryItems = queryItems
    }
}

func urlAssembler(_ pathParts:String...) -> URL? {
    return URL(string:assemblePath(pathParts, prependSeparator: false))
}

func pathAssembler(_ pathParts:String...) -> String? {
    return URL(string:assemblePath(pathParts))?.absoluteString
}

func urlAssembler(url:URL, _ pathParts:String...) -> URL? {
   let urlString = url.absoluteString
    var mPathParts = pathParts
    mPathParts.insert(urlString, at:0)
    return URL(string:assemblePath(mPathParts, prependSeparator: false))
}

func urlAssembler(baseString:String, _ pathParts:String...) -> URL? {
    var mPathParts = pathParts
    mPathParts.insert(baseString, at:0)
    return URL(string:assemblePath(mPathParts, prependSeparator: false))
}


func urlFromPath(scheme:String = "https", host:String, path:String, port:Int? = nil) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    if let port  { components.port = port }

    components.path = path
    
    guard let url = components.url else {
        throw APIngError("Invalid url for path")
    }
    return url
}

func urlFromPathComponents(scheme:String = "https", host:String, components pathParts:[String], port:Int? = nil) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    if let port  { components.port = port }

    components.path = assemblePath(pathParts)
    
    guard let url = components.url else {
        throw APIngError("Invalid url for path")
    }
    return url
}

private func assemblePath(_ pathParts:[String], prependSeparator:Bool = true) -> String {
    var joined = prependSeparator ? "/" : ""
        let trimmed:[String] = pathParts.compactMap({ String($0.trimmingCharacters(in: CharacterSet(charactersIn: "/")))})
    joined += trimmed.joined(separator: "/")
    return joined
}

func urlFromEndpoint(scheme:String = "https", host:String, apiBase:String = "", endpoint:Endpoint, port:Int? = nil) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    if let port  { components.port = port }

    components.path = assemblePath([apiBase, endpoint.path])

    if !endpoint.queryItems.isEmpty {
        components.queryItems = endpoint.queryItems
    }
    
    guard let url = components.url else {
        print("components:\(components)")
        throw APIngError("Invalid url for endpoint")
    }
    return url
}

