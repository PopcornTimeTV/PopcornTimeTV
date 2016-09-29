#!/usr/bin/env xcrun swift

import Foundation

public extension URLSession {
    
    /// Return data from synchronous URL request
    public static func requestSynchronousData(_ request: URLRequest) -> Data? {
        var data: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { (taskData, _, error) in
            data = taskData
            if data == nil, let error = error {print(error)}
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return data
    }
    
    /// Return data synchronous from specified endpoint
    public static func requestSynchronousDataWithURLString(_ requestString: String) -> Data? {
        guard let url = URL(string:requestString) else {return nil}
        let request = URLRequest(url: url)
        return URLSession.requestSynchronousData(request)
    }
    
    /// Return JSON synchronous from URL request
    public static func requestSynchronousJSON(_ request: URLRequest) -> Any? {
        guard let data = URLSession.requestSynchronousData(request) else {return nil}
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    /// Return JSON synchronous from specified endpoint
    public static func requestSynchronousJSONWithURLString(_ requestString: String) -> Any? {
        guard let url = URL(string: requestString) else {return nil}
        var request = URLRequest(url:url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return URLSession.requestSynchronousJSON(request)
    }
}

func run(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = args
    print(args)
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func input(_ input: String) -> String {
    print(input)
    let keyboard = FileHandle.standardInput
    let inputData = keyboard.availableData
    let string = String(data: inputData, encoding: .utf8)!
    return string.replacingOccurrences(of: "\n", with: "")
}

// Fetch the latest version
print("# Fetching the latest changes from github...")
run("-c", "git stash", "git fetch", "git rebase")


// Fetch the releases
print("\n# Fetching the latest verion info...")

var versions = [String]()
if let jsonData = URLSession.requestSynchronousJSONWithURLString("https://api.github.com/repos/PopcornTimeTV/PopcornTimeTV/releases") as? [[String : AnyObject]] {
    
    for info in jsonData {
        if let string = info["tag_name"] as? String {
            versions.append(string)
        }
    }
    
    for i in 0..<versions.count {
        print(versions[i])
    }
}

// Ask the user what version
let version = input("Enter the version number: ")


// Make sure the tag exsists in versions
if version.lowercased() != "master" {
    if !versions.contains(version) {
        print("You entered an incorrect version number. Please rerun this script and try again.")
        exit(0)
    }
}

// Checkout the tag
print("\n# Checking out tag \(version)...")
run("-c", "git checkout \(version)", "git pop")

// Check if cocoapods is installed
let podsInstalled = input("Do you have cocoapods installed? (Enter Yes or No): ").lowercased()
if podsInstalled.range(of: "no") != nil {
    print("Installing cocoapod gem...")
    run("-c", "sudo gem install cocoapods")
}

// Install all of the pods
print("Updating and installing Cocoapods...")
run("-c","rm -rf ~/.cocoapods/repos/PopcornTimeTV")
run("-c","rm -rf Podfile.lock")
run("-c","pod cache clean --all")
run("-c","rm -rf ~/Library/Developer/Xcode/DerivedData/PopcornTime-*")
run("-c","pod repo remove popcornmaster;pod setup;pod repo update")
run("-c","pod install")
run("-c","pod update")


// Open Xcode
print("Opening Xcode...")
run("-c", "open PopcornTime.xcworkspace")

// Thank you message
print("Thanks for installing PopcornTime. When a new update is released re-run this script and select the new version.")
