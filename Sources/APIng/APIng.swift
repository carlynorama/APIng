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
    static let exampleMultiPartDict:Dictionary<String, CustomStringConvertible> = [
        "twenty_pi": 3.1415926535897932384,
        "preamble": "When in the course of human events...",
        "shoop": "HoopdiDoop",
        ]


    public static func main() async throws  {
        
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
        print("---")

        // let testingGetURL = urlAssembler(baseString: "http://localhost:8080", "api/v1")!
        // try await serverHello(from: testingGetURL)

        //let testingPostURL = urlAssembler(baseString: "http://localhost:8080", "api/v1")!

        //try await post_URLEncoded_uploadFrom(baseUrl:testingPostURL, formData:exampleStatusUpdate_dict)
        // try await post_URLEncoded_manualBody(baseUrl:testingPostURL, formData:exampleStatusUpdate_dict)

        //try await post_FormBody_uploadFrom(baseUrl:testingPostURL, formData:exampleMultiPartDict) 
        //try await post_FormBody_manualBody(baseUrl:testingPostURL, formData:exampleMultiPartDict)


        

        try DotEnv.loadDotEnv()

    //---------------- CONFIRMED - GET TIMELINE WORKS
        // let timeLineEndpoint = Endpoint(path: "/api/v1/timelines/public", queryItems: [URLQueryItem(name: "limit", value: "5")])
        // let timelineURL = try urlFromEndpoint(host: ProcessInfo.processInfo.environment["SERVER_NAME"]!, endpoint: timeLineEndpoint)
        // print(timelineURL.absoluteString)
        // let result = try await getRawString(from: timelineURL)
        // print(result)

    //---------------- CONFIRMED - NEW STATUS AS URLENCODED WORKS (BOTH METHODS)
        // let statusEndpoint = Endpoint(path:"/api/v1/statuses", queryItems: [])
        // //let statusEndpointURL = urlAssembler("http://localhost:8080", statusEndpoint.path)!
        // let statusEndpointURL = try urlFromEndpoint(host: ProcessInfo.processInfo.environment["SERVER_NAME"]!, endpoint: statusEndpoint)
        // print("trying \(statusEndpointURL.absoluteString)")

        // let exampleBasicStatus = [
        //     "status":"This is a really really interesting message. \(Date.now.ISO8601Format())"
        // ]

        //try await post_URLEncoded_uploadFrom(baseUrl: statusEndpointURL, formData: exampleBasicStatus, withAuth:true)
        //try await post_URLEncoded_manualBody(baseUrl: statusEndpointURL, formData: exampleBasicStatus, withAuth:true)
        
    //---------------- CONFIRMED - NEW STATUS AS FORM DATA WORKS (BOTH METHODS)
    
        let statusEndpoint = Endpoint(path:"/api/v1/statuses", queryItems: [])
        //let statusEndpointURL = urlAssembler("http://localhost:8080", statusEndpoint.path)!
        let statusEndpointURL = try urlFromEndpoint(host: ProcessInfo.processInfo.environment["SERVER_NAME"]!, endpoint: statusEndpoint)
        print("trying \(statusEndpointURL.absoluteString)")

        let exampleBasicStatus = [
            "status":"This is a really really interesting message. \(Date.now.ISO8601Format())"
        ]

        try await post_FormBody_uploadFrom(baseUrl:statusEndpointURL, formData:exampleBasicStatus, withAuth:true)
        //try await post_FormBody_manualBody(baseUrl:statusEndpointURL, formData:exampleBasicStatus, withAuth:true)

    //---------------- CONFIRMED - UPLOAD MEDIA FILE WORKS (BOTH METHODS)
    // Media uploads will fail if fileNames are not included on Form Data. 

    //     let mediaEndpoint = Endpoint(path:"/api/v2/media", queryItems: [])
    //     //let mediaEndpointURL = urlAssembler("http://localhost:8080", mediaEndpoint.path)!
    //     //let mediaEndpointURL = URL(string: "https://httpbin.org/post")!
    //     let mediaEndpointURL = try urlFromEndpoint(host: ProcessInfo.processInfo.environment["SERVER_NAME"]!, endpoint: mediaEndpoint)
    //     print("trying \(mediaEndpointURL.absoluteString)")

    //     //let fileAttachment =  try loadDataFromFile(path: "string_load_test.txt")
    //     let fileAttachment =  try loadDataFromFile(path: "small_test.png", limitTypes: [.image])


    //     let exampleMediaAttachmentConfig = [
    //             "description":"This is a pretty picture. \(Date.now.ISO8601Format())"
    //     ]

    //     let (boundary, body) = try makeBodyData(stringItems: exampleMediaAttachmentConfig, dataAttachments: ["file" : fileAttachment])

    //     //try await post_FormBody_uploadFrom(baseUrl: mediaEndpointURL, dataToSend: body, boundary: boundary, withAuth:true)
    //     try await post_FormBody_manualBody(baseUrl:mediaEndpointURL, dataToSend: body, boundary: boundary, withAuth:true)

    // 

        //---------------- CONFIRMED WORKS - Dictionary Conversion

        // struct TestEncodableStruct:Encodable {
        //     let hello = "World"
        //     let meaningOfLife = 42
        //     let optHello:String? = "World"
        //     let optMeaningOfLife:Int? = nil
        // }

        // struct TestStruct {
        //     let hello = "World".data(using: .utf8)
        //     let meaningOfLife = 42
        //     let optHello:URL? = URL(string: "http://example.com")
        //     let optMeaningOfLife:Int? = nil
        // }

        // if let newDict = makeDictionary(from: TestStruct()) {
        // print(String(describing:newDict))
        // for (key, value) in newDict {
        //     print(key, value)
        // }
        // } else {
        //     print("could not make a dictionary")
        // }

        // let otherDict = makeDictionary(fromEncodable: TestEncodableStruct()) 
        // print(String(describing:otherDict))
        // for (key, value) in otherDict {
        //     print(key, value)
        // }

        // TESTING - RECEiVE EVENT STREAMS

        //Yes, receives stream. 
       // try await streamReceiverTest(streamURL:URL(string:"https://httpbin.org/get")!, session:URLSession.shared) 
        // try await streamReceiverTestWithManualHeader(streamURL:URL(string:"https://mastodon.social/api/v1/streaming/public")!, session:URLSession.shared) 
        // try await streamReceiverTestWithManualHeader(streamURL:URL(string:"https://httpbin.org/get")!, session:URLSession.shared) 

        //TESTING - Turn on and off event stream
        // let url = URL(string:"https://mastodon.social/api/v1/streaming/public")!
        // let listener = SSEStreamListener(url: url, urlSession: URLSession.shared)
        // try listener.startListening()

        //TESTING - Authed StreamListener
        let url = URL(string:"https://social.cozytronics.com/api/v1/streaming/tipsyrobot/notification")!
        try await streamReceiverWithAuth(streamURL: url, session: URLSession.shared, withAuth: true)

     }
}
