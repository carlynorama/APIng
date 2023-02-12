import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func printData(data:Data) {
    if let string = String(data:data, encoding: .utf8) {
        if !string.isEmpty {
            print("\(string)")
        }  else { print("String was empty") }
    } else { print("Data is not utf8 encodable.") }
    
}


@main
public struct APIng {

    public static var shared = APIng()
    public private(set) var text = "Hello, World!"
    
    static let host = "social.cozytronics.com"
    static let scheme: String = "https"
    static let apiBase: String = "/api"

    static let exampleEndpoint = Endpoint(path: "/api/v1/timelines/public", queryItems: [URLQueryItem(name: "limit", value: "5")])

    static let exampleStatusUpdate_uqi = URLQueryItem(name:"status", value:"I am a new status to post!")
    static let exampleStatusUpdate_dict = ["status":"I am a new dictionary status to post"]
    static let exampleStatusUpdate_dictCSR = ["status": 3.1415926535897932384]


    public static func main() {
        print(shared.text)
        let pathURL = try? urlFromPath(host: host, path: apiBase).absoluteString
        let pathFromComponents = try? urlFromPathComponents(host:host, components:[apiBase, "v1", "timelines/public"]).absoluteString
        let pathFromEndpoint = try? urlFromEndpoint(host:host, endpoint:exampleEndpoint).absoluteString
        let esu_uqi = try? makeURLEncodedString(queryItems: [exampleStatusUpdate_uqi])
        let esu_dict = try? makeURLEncodedString(formItems:  exampleStatusUpdate_dict)
        let esu_dictCSR = try? makeURLEncodedString(formItems:  exampleStatusUpdate_dictCSR)
        let urlFreeForm = URL(string: "https://example.com:1313/hello/")!
        let urlAssembler_1 = urlAssembler("https://example.com:1313/hello/", "/more", "parts", "that/", "/are/", "sloppy")!
        let urlAssembler_2 = urlAssembler(url: urlFreeForm, "/more", "parts", "that/", "/are/", "sloppy")!
        let urlAssembler_3 = urlAssembler(baseString: "https://example.com:1313/hello/", "/more", "parts", "that/", "/are/", "sloppy")!
        let pathAssembler_1 = pathAssembler("https://example.com:1313/hello/", "/more", "parts", "that/", "/are/", "sloppy")!
        let pathAssembler_2 = pathAssembler("/more", "parts", "that/", "/are/", "sloppy")!
        print("---")
        print("\(pathURL!)")
        print("\(pathFromComponents!)")
        print("\(pathFromEndpoint!)")
        print("\(esu_uqi!)")
        print("\(esu_dict!)")
        print("\(esu_dictCSR!)")
        print("---")
        print("\(urlFreeForm.absoluteString)")
        print("\(urlAssembler_1.absoluteString)")
        print("\(urlAssembler_2.absoluteString)")
        print("\(urlAssembler_3.absoluteString)")
        print("\(pathAssembler_1)")
        print("\(pathAssembler_2)")

    }
}
