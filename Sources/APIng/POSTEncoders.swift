//ACTUAL SPEC
//https://www.rfc-editor.org/rfc/rfc7578


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

//MARK: URL Encoding

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


//MARK: FORM Encoding

func makeBodyData(formItems:Dictionary<String, CustomStringConvertible>) throws -> (boundary:String, body:Data) {
    let boundary = "Boundary--\(UUID().uuidString)"
    var bodyData = Data()
    for (key, value) in formItems {
        bodyData = try appendTextField(data: bodyData, label: key, value: String(describing: value), boundary: boundary)
    }
    bodyData = appendTerminationBoundary(data: bodyData, boundary: boundary)
    return (boundary, bodyData)
}

//Media uploads will fail if fileName is not included, regardless of MIME/Type. 
func makeBodyData(stringItems:Dictionary<String, CustomStringConvertible>, dataAttachments:[String:(fileName:String, data:Data, mimeType:String)]) throws -> (boundary:String, body:Data) {
    let boundary = "Boundary--\(UUID().uuidString)"
    var bodyData = Data()
    for (key, value) in stringItems {
        bodyData = try appendTextField(data: bodyData, label: key, value: String(describing: value), boundary: boundary)
    }

    for (key, value) in dataAttachments {
        bodyData = try appendDataField(data: bodyData, label: key, dataToAdd: value.data, mimeType: value.mimeType, fileName: value.fileName, boundary: boundary)
    }

    bodyData = appendTerminationBoundary(data: bodyData, boundary: boundary)
    return (boundary, bodyData)
}

//TODO: All this copying... inout instead? make extension? 

func appendTextField(data:Data, label key: String, value: String, boundary:String) throws -> Data {
    var copy = data
    let formFieldData = try textFormField(label:key, value:value, boundary:boundary)
    copy.append(formFieldData)
    return copy
}

func appendDataField(data:Data, label key: String, dataToAdd: Data, mimeType: String, fileName:String? = nil, boundary:String) throws -> Data {
    var copy = data
    let formFieldData = try dataFormField(label:key, data: dataToAdd, mimeType: mimeType, fileName:fileName, boundary:boundary)
    copy.append(formFieldData)
    return copy
}

func appendTerminationBoundary(data:Data, boundary:String) -> Data {
    var copy = data
    let boundaryData = "--\(boundary)--".data(using: .utf8)
    copy.append(boundaryData!) //TODO throw instead
    return copy
}

func textFormField(label key: String, value: String, boundary:String) throws -> Data {
    var fieldString = "--\(boundary)\r\n"
    fieldString += "Content-Disposition: form-data; name=\"\(key)\"\r\n"
    fieldString += "Content-Type: text/plain; charset=UTF-8\r\n"
    fieldString += "\r\n"
    fieldString += "\(value)\r\n"

   let fieldData = fieldString.data(using: .utf8)
   if fieldData == nil {
    throw APIngError("couldn't make data from field \(key), \(value) with \(boundary)")
   }
    return fieldData!
}

func dataFormField(label key: String, data: Data, mimeType: String, fileName:String? = nil, boundary:String) throws -> Data {
    var fieldData = Data()

    try fieldData.append("--\(boundary)\r\n")
    if let fileName {
        try fieldData.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\";\r\n")
    } else {
        try fieldData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n")
    }
    
    try fieldData.append("Content-Type: \(mimeType)\r\n")
    try fieldData.append("\r\n")
    fieldData.append(data)
    try fieldData.append("\r\n")

    return fieldData as Data
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) throws {
        if let data = string.data(using: encoding) {
            append(data)
        } else {
            throw APIngError("extension Data append: Couldn't make data from string")
        }
    }
    
    func appending(_ string: String, using encoding: String.Encoding = .utf8) throws -> Self? {
        if let data = string.data(using: encoding) {
            var copy = self
            copy.append(data)
            return copy
        } else {
            throw APIngError("extension Data appending: Couldn't make data from string.")
        }
    }
}