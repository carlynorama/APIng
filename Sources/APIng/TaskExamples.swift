

//https://www.hackingwithswift.com/quick-start/concurrency/how-to-control-the-priority-of-a-task


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


func cancellingFetchUpdates2<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type, dontBother:Bool = true) async throws -> [Item] {
    let itemsTask = Task { () -> [Item] in
        let (data, _) = try await session.data(from: url) 
        if Task.isCancelled { return [] }
        return try JSONDecoder().decode([Item].self, from: data) 
    } 
    
    if (dontBother) {
        itemsTask.cancel()
    }
    //a a Result<String, Error>
    let result = await itemsTask.result
   
    let items = try result.get()
    return items
}


// func cancellingStream<Item:Decodable>(streamURL:URL, session:URLSession, ofType:Item.Type) async throws -> [Item] {
//     let itemsTask = Task { () -> [Item] in
//         let (bytes, _) = try await session.bytes(from:streamURL)
//         try Task.checkCancellation() //will make sure task hasn't been canceled before continuing. 
//         return try JSONDecoder().decode([Item].self, from: data) 
//     } 
    
//     //a a Result<String, Error>
//     let result = await itemsTask.result
   
//     let items = try result.get()
//     return items
// }


func cancellingFetchUpdates<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type) async throws -> [Item] {
    let itemsTask = Task { () -> [Item] in
        let (data, _) = try await session.data(from: url) 
        try Task.checkCancellation() //will make sure task hasn't been canceled before continuing. 
        return try JSONDecoder().decode([Item].self, from: data) 
    } 
    
    //a a Result<String, Error>
    let result = await itemsTask.result
   
    let items = try result.get()
    return items
}


func passingFetchUpdates<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type) async throws -> [Item] {
    let itemsTask = Task { () -> [Item] in
        let (data, _) = try await session.data(from: url) 
        return try JSONDecoder().decode([Item].self, from: data) 
    } 
    
    //a a Result<String, Error>
    let result = await itemsTask.result
   
    let items = try result.get()
    return items
}

enum LoadError: Error {
    case fetchFailed, decodeFailed
}

func catchingFetchUpdates<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type) async -> [Item] {
    let itemsTask = Task { () -> [Item] in
        let data:Data
        do { (data, _) = try await session.data(from: url) }
        catch { throw LoadError.fetchFailed }
        
        do { return try JSONDecoder().decode([Item].self, from: data) } 
        catch { throw LoadError.decodeFailed}
    }

    //a a Result<String, Error>
    let result = await itemsTask.result

   do {
        let items = try result.get()
        return items
    } catch LoadError.fetchFailed {
        print("Unable to fetch the quotes.")
        return []
    } catch LoadError.decodeFailed {
        print("Unable to convert quotes to text.")
        return []
    } catch {
        print("Unknown error.")
        return []
    }
}


func simpleFetchUpdates<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type) async {
    let itemsTask = Task { () -> [Item] in
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Item].self, from: data)
    }

    do {
        let items = try await itemsTask.value
        //do something with items.
    } catch {
        print("There was an error loading user data.")
    }
}



//await fetchUpdates(url:URL, session:URLSession, ofType:Item.Type)