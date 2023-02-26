import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

//TODO: RunLoop keeps it open, bu then REALLY keeps it open. Fix that.
//RunLoops aren't supposed to be used in an async context
//AsyncParsableCommand might be the solution from ArgumentParser
//https://stackoverflow.com/questions/71298098/swift-async-method-call-for-a-command-line-app

//https://stackoverflow.com/questions/32140470/swift-nstimer-didnt-work
//https://stackoverflow.com/questions/64453233/how-to-use-runloop-in-a-command-line-tool-to-use-combine-timer-pubish
//https://www.hackingwithswift.com/articles/117/the-ultimate-guide-to-timer
//https://stackoverflow.com/questions/70085517/update-cli-progress-bar-in-async-task
// https://stackoverflow.com/questions/41529052/how-do-i-manually-retain-in-swift-with-arc

// Could always do this on the main thread...
// while true {
//     print("hello")
//     Thread.sleep(forTimeInterval: 0.1)
// }

func timerPosting(url:URL, message:String, interval:TimeInterval = 30.0) -> Timer {
    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
        Task { 
        let message = "\(message)... \(Date.now)"
        try await post_URLEncoded_uploadFrom(baseUrl:url, formData:["status":message], withAuth:true)
        }
    }
    timer.tolerance = 1.0 //give it some latitude to timer coalesce

    withExtendedLifetime(timer) {
        RunLoop.current.run()
        //RunLoop.current.add(timer, forMode: .common)
    }
    return timer
}

func postForFiniteTime(url:URL, message:String, interval:TimeInterval = 30.0, cutOff:TimeInterval = 60.0) -> Timer {
    let startTime = Date.now
    let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { thisTimer in
        let currentTime = Date.now
        if currentTime <= (startTime + cutOff) { 
             //lets it run one last time. 
            let message = "\(message)... \(currentTime)"
            //don't love the dangling task...
            Task { 
                try await post_URLEncoded_uploadFrom(baseUrl:url, formData:["status":message], withAuth:true)
            }
        } else {
            print("One last time.")
            thisTimer.invalidate()
        
        }
       
        
    }
    timer.tolerance = 1.0 //give it some latitude to timer coalesce


    return timer
}