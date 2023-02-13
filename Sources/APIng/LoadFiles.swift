import Foundation
import UniformTypeIdentifiers

func loadFile(url:URL, limitTypes uttypes: [UTType] = []) throws -> (fileName:String, data:Data, mimeType:String) {
        if !uttypes.isEmpty {
            guard url.pointsToItemOfType(uttypes: uttypes) else {
                throw APIngError("MinimalAttachable: Does not conform to allowed types.")
            }
        }
        guard let data = try? Data(contentsOf: url) else {
            throw APIngError("MinimalAttachable:No data for the file at the location given.")
        }
        let mimeType = url.mimeType()
        // let ext = url.pathExtension
        // var leaf = url.lastPathComponent
        // if !ext.isEmpty {
        //     leaf = leaf.split(separator: ".").dropLast().joined(separator: ".") //incase there were other periods in the file name
        // }
        
        return (fileName: url.lastPathComponent, data: data, mimeType:mimeType)
    }