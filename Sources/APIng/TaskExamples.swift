

//https://www.hackingwithswift.com/quick-start/concurrency/how-to-control-the-priority-of-a-task
//https://www.hackingwithswift.com/quick-start/concurrency/how-to-make-a-task-sleep


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

//https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
func requestInChunks(data:inout Data, url:URL, session:URLSession, offset:Int, length:Int) async throws {
    var urlRequest = URLRequest(url: url)
    urlRequest.addValue("bytes=\(offset)-\(offset + length - 1)", forHTTPHeaderField: "Range")

    let (asyncBytes, response) = try await
        session.bytes(for: urlRequest, delegate: nil)

    guard (response as? HTTPURLResponse)?.statusCode == 206 else { //NOT 200!!
        throw APIngError("The server responded with an error.")
    }
    
    for try await byte in asyncBytes { 
        data.append(byte) 
        if data.count % 100 == 0 {
            print(data.count) 
        }  
    }
}



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


//This does print
func test_funcCondition(timeOut:TimeInterval, url:URL, session:URLSession) async throws {
         
    let (asyncBytes, _) = try await session.bytes(from: url)

    let deadLine = Date.now + timeOut
    var data = Data()

   func someConditionCheck(_ deadline:Date) -> Bool {
        Date.now > deadLine
    }
    
    for try await byte in asyncBytes {   
        //await Task.yield()
        if someConditionCheck(deadLine) {  
            asyncBytes.task.cancel()
            //session.invalidateAndCancel()
            print("trying to cancel...")
        } 
        //let bytesTask = asyncBytes.task
        data.append(byte) 
        if data.count % 100 == 0 {
            print(data.count) 
        }              
    }
}

func test_customIterator(timeOut:TimeInterval, url:URL, session:URLSession) async throws {
         
    let (asyncBytes, _) = try await session.bytes(from: url)

    let deadLine = Date.now + timeOut
    var data = Data()

   func someConditionCheck(_ deadline:Date) -> Bool {
        Date.now > deadLine
    }

    //could also be asyncBytes.lines.makeAsyncIterator(), etc.
    var iterator = asyncBytes.makeAsyncIterator()
    while !someConditionCheck(deadLine) {
        let byte = try await iterator.next()
        data.append(byte!) 
        //if data.count % 100 == 0 {
            print(data.count) 
        //}           
    }
    //make sure to still tell URLSession you aren't listening anymore.
    asyncBytes.task.cancel()

}

func test_timeOut(timeOut:TimeInterval, url:URL, session:URLSession) async throws {
         
    let (asyncBytes, _) = try await session.bytes(from: url)

    var data = Data()

    Task { try await Task.sleep(for: .seconds(timeOut)); asyncBytes.task.cancel() }
    //     DispatchQueue.main.asyncAfter(deadline: .now() + timeOut) { asyncBytes.task.cancel() }
    
    for try await byte in asyncBytes {
        if Task.isCancelled { print ("cancelled") }
        data.append(byte); 
        if data.count % 100 == 0 {
            print(data.count) 
        }    
        // if data.count % 1256 == 0 {
        //     print(data.count) 
        // }      
    }
}

// func customStreamIterator<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type, dontBother:Bool = true) async throws -> [Item] {
//     let url = URL(string: "https://hws.dev/users.csv")!

//     var iterator = url.lines.makeAsyncIterator()

//     if let line = try await iterator.next() {
//         print("The first user is \(line)")
//     }

//     for i in 2...5 {
//         if let line = try await iterator.next() {
//             print("User #\(i): \(line)")
//         }
//     }

//     var remainingResults = [String]()

//     while let result = try await iterator.next() {
//         remainingResults.append(result)
//     }

//     print("There were \(remainingResults.count) other users.")
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


func simpleFetchUpdates<Item:Decodable>(url:URL, session:URLSession, ofType:Item.Type) async -> [Item] {
    let itemsTask = Task { () -> [Item] in
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Item].self, from: data)
    }

    do {
        let items = try await itemsTask.value
        return items
    } catch {
        print("There was an error loading user data.")
        return []
    }
}



//await fetchUpdates(url:URL, session:URLSession, ofType:Item.Type)


//https://www.swiftbysundell.com/articles/async-sequences-streams-and-combine/

