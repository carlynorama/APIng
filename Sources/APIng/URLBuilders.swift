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


func urlFromPath(scheme:String = "https", host:String, path:String) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = path
    
    guard let url = components.url else {
        throw APIngError("Invalid url for path")
    }
    return url
}

func urlFromPathComponents(scheme:String = "https", host:String, components pathParts:[String]) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host

    components.path = assemblePath(pathParts)
    
    guard let url = components.url else {
        throw APIngError("Invalid url for path")
    }
    return url
}

private func assemblePath(_ pathParts:[String]) -> String {
        let trimmed:[String] = pathParts.compactMap({ String($0.trimmingCharacters(in: CharacterSet(charactersIn: "/")))})
    let joined = "/" + trimmed.joined(separator: "/")
    return joined
}

func urlFromEndpoint(scheme:String = "https", host:String, apiBase:String = "", endpoint:Endpoint) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host

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

