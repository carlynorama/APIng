import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif




func post_URLEncoded_uploadFrom(baseUrl:URL, formData:Dictionary<String, CustomStringConvertible>) async throws {
    //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
    var request = URLRequest(url: baseUrl)
    request.httpMethod = "POST"

    let dataToSend = try makeURLEncodedString(formItems: formData).data(using: .utf8)

    let (responseData, response) = try await URLSession.shared.upload(for: request, from: dataToSend!, delegate: nil)

    print("post_URLEncoded_uploadFrom")
    print(response)
    print(String(data:responseData, encoding: .utf8) ?? "Nothing")

    //Some options for handling response:

    // guard let response = response as? HTTPURLResponse,
    //         (200...299).contains(response.statusCode)  else  {
    //             throw APIngError("Not a success.")
    // }

    //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
    //if let json = jsonData as? [String: Any] { print(json) }
    //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
    //return answer.Message

}

func post_URLEncoded_manualBody(baseUrl:URL, formData:Dictionary<String, CustomStringConvertible>) async throws {
    //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
    var request = URLRequest(url: baseUrl)
    request.httpMethod = "POST"

    request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

    let dataToSend = try makeURLEncodedString(formItems: formData).data(using: .utf8)
    request.httpBody = dataToSend

    let (responseData, response) =  try await URLSession.shared.data(for: request)

    print("post_URLEncoded_manualBody")
    print(response)
    print(String(data:responseData, encoding: .utf8) ?? "Nothing")

    //Some options for handling response:

    // guard let response = response as? HTTPURLResponse,
    //         (200...299).contains(response.statusCode)  else  {
    //             throw APIngError("Not a success.")
    // }

    //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
    //if let json = jsonData as? [String: Any] { print(json) }
    //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
    //return answer.Message

}

// func post_FormBody_uploadFrom(baseUrl:URL, formData:Dictionary<String, CustomStringConvertible>) async throws {
//     let (_, dataToSend) = try makeBodyData(formItems: formData)
//     try await post_FormBody_uploadFrom(baseUrl:baseUrl, dataToSend:dataToSend)
// }


// //Skeptical this works for anything other than URLencode...  
// func post_FormBody_uploadFrom(baseUrl:URL, dataToSend:Data) async throws {
//     //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
//     var request = URLRequest(url: baseUrl)
//     request.httpMethod = "POST"

//     let (responseData, response) = try await URLSession.shared.upload(for: request, from: dataToSend, delegate: nil)

//     print("post_FormBody_uploadFrom")
//     print(response)
//     print(String(data:responseData, encoding: .utf8) ?? "Nothing")

//     //Some options for handling response:

//     // guard let response = response as? HTTPURLResponse,
//     //         (200...299).contains(response.statusCode)  else  {
//     //             throw APIngError("Not a success.")
//     // }

//     //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
//     //if let json = jsonData as? [String: Any] { print(json) }
//     //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
//     //return answer.Message

// }


func post_FormBody_manualBody(baseUrl:URL, formData:Dictionary<String, CustomStringConvertible>) async throws {
    let (boundary,dataToSend) = try makeBodyData(formItems: formData)
    try await post_FormBody_manualBody(baseUrl:baseUrl, dataToSend:dataToSend, boundary: boundary)
}

func post_FormBody_manualBody(baseUrl:URL, dataToSend:Data, boundary:String) async throws {
    //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
    var request = URLRequest(url: baseUrl)
    request.httpMethod = "POST"

    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.httpBody = dataToSend

    let (responseData, response) =  try await URLSession.shared.data(for: request)

    print("post_FormBody_manualBody")
    print(response)
    print(String(data:responseData, encoding: .utf8) ?? "Nothing")

    //Some options for handling response:

    // guard let response = response as? HTTPURLResponse,
    //         (200...299).contains(response.statusCode)  else  {
    //             throw APIngError("Not a success.")
    // }

    //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
    //if let json = jsonData as? [String: Any] { print(json) }
    //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
    //return answer.Message

}

func post_ApplicationJSON_manualBody(baseUrl:URL, itemToSend:Encodable) async throws {
    //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
    var request = URLRequest(url: baseUrl)
    request.httpMethod = "POST"

    let jsonData = try JSONSerialization.data(withJSONObject: itemToSend, options: .fragmentsAllowed)

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData

    let (responseData, response) =  try await URLSession.shared.data(for: request)

    print("post_ApplicationJSON_manualBody")
    print(response)
    print(String(data:responseData, encoding: .utf8) ?? "Nothing")

    //Some options for handling response:

    // guard let response = response as? HTTPURLResponse,
    //         (200...299).contains(response.statusCode)  else  {
    //             throw APIngError("Not a success.")
    // }

    //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
    //if let json = jsonData as? [String: Any] { print(json) }
    //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
    //return answer.Message

}

func post_ApplicationJSON_uploadFrom(baseUrl:URL, itemToSend:Encodable) async throws {
    //cachePolicy: URLRequest.CachePolicy, timeoutInterval: TimeInterval
    var request = URLRequest(url: baseUrl)
    request.httpMethod = "POST"

    let jsonData = try JSONSerialization.data(withJSONObject: itemToSend, options: .fragmentsAllowed)

    let (responseData, response) = try await URLSession.shared.upload(for: request, from: jsonData, delegate: nil)

    print("post_ApplicationJSON_uploadFrom")
    print(response)
    print(String(data:responseData, encoding: .utf8) ?? "Nothing")

    //Some options for handling response:

    // guard let response = response as? HTTPURLResponse,
    //         (200...299).contains(response.statusCode)  else  {
    //             throw APIngError("Not a success.")
    // }

    //let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
    //if let json = jsonData as? [String: Any] { print(json) }
    //let answer = try JSONDecoder().decode(BackendMessage.self, from: data)
    //return answer.Message

}