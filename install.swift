#!/usr/bin/env xcrun swift

import Foundation

public extension NSURLSession {
    
    /// Return data from synchronous URL request
    public static func requestSynchronousData(request: NSURLRequest) -> NSData? {
        var data: NSData? = nil
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {
            taskData, _, error -> () in
            data = taskData
            if data == nil, let error = error {print(error)}
            dispatch_semaphore_signal(semaphore);
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        return data
    }
    
    /// Return data synchronous from specified endpoint
    public static func requestSynchronousDataWithURLString(requestString: String) -> NSData? {
        guard let url = NSURL(string:requestString) else {return nil}
        let request = NSURLRequest(URL: url)
        return NSURLSession.requestSynchronousData(request)
    }
    
    /// Return JSON synchronous from URL request
    public static func requestSynchronousJSON(request: NSURLRequest) -> AnyObject? {
        guard let data = NSURLSession.requestSynchronousData(request) else {return nil}
        return try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    }
    
    /// Return JSON synchronous from specified endpoint
    public static func requestSynchronousJSONWithURLString(requestString: String) -> AnyObject? {
        guard let url = NSURL(string: requestString) else {return nil}
        let request = NSMutableURLRequest(URL:url)
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return NSURLSession.requestSynchronousJSON(request)
    }
}

func run(args: String...) -> Int32 {
    let task = NSTask()
    task.launchPath = "/bin/bash"
    task.arguments = args
    print(args)
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func input(input: String) -> String {
    print(input)
    let keyboard = NSFileHandle.fileHandleWithStandardInput()
    let inputData = keyboard.availableData
    let string = NSString(data: inputData, encoding:NSUTF8StringEncoding) as! String
    return string.stringByReplacingOccurrencesOfString("\n", withString: "")
}

// Fetch the latest version
print("# Fetching the latest changes from github...")
run("-c", "git stash", "git fetch", "git rebase")


// Fetch the releases
print("\n# Fetching the latest verion info...")

var versions = [String]()
if let jsonData = NSURLSession.requestSynchronousJSONWithURLString("https://api.github.com/repos/popcornMaster/PopcornTimeTV/releases") as? [[String : AnyObject]] {
    
    for info in jsonData {
        if let string = info["tag_name"] as? String {
            versions.append(string)
        }
    }
    
    for i in 0...versions.count-1 {
        print(versions[i])
    }
}

// Ask the user what version
let version = input("Enter the version number: ")


// Make sure the tag exsists in versions
if version.lowercaseString != "master" {
    if !versions.contains(version) {
        print("You entered an incorrect version number. Please rerun this script and try again.")
        exit(0)
    }
}

// Checkout the tag
print("\n# Checking out tag \(version)...")
run("-c", "git checkout \(version)", "git pop")

// Check if cocoapods is installed
let podsInstalled = input("Do you have cocoapods installed? (Enter Yes or No): ").lowercaseString
if podsInstalled.rangeOfString("no") != nil {
    print("Installing cocoapod gem...")
    run("-c", "sudo gem install cocoapods")
}

// Install all of the pods
print("Updating and installing Cocoapods...")
run("-c","rm -rf ~/.cocoapods/repos/popcornmaster")
run("-c","rm -rf Podfile.lock")
run("-c","pod cache clean --all")
run("-c","rm -rf ~/Library/Developer/Xcode/DerivedData/PopcornTime-*")
run("-c","pod setup;pod repo update")
run("-c","pod install")
run("-c","pod update")


// Open Xcode
print("Opening Xcode...")
run("-c", "open PopcornTime.xcworkspace")

// Thank you message
print("Thanks for installing PopcornTime. When a new update is released re-run this script and select the new version.")
