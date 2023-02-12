import Foundation

//TODO: All this copying... inout instead? make extension? 

func appendTextField(data:Data, label key: String, value: String, boundary:String) throws -> Data {
    var copy = data
    let formFieldData = try textFormField(label:key, value:value, boundary:boundary)
    copy.append(formFieldData)
    return copy
}

func appendDataField(data:Data, label key: String, dataToAdd: Data, mimeType: String, boundary:String) throws -> Data {
    var copy = data
    let formFieldData = try dataFormField(label:key, data: dataToAdd, mimeType: mimeType, boundary:boundary)
    copy.append(formFieldData)
    return copy
}

func appendTerminationBoundary(data:Data, boundary:String) -> Data {
    var copy = data
    let boundaryData = "--\(boundary)\r\n".data(using: .utf8)
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

func dataFormField(label key: String, data: Data, mimeType: String, boundary:String) throws -> Data {
    var fieldData = Data()

    try fieldData.append("--\(boundary)\r\n")
    try fieldData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n")
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