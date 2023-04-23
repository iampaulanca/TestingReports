//
//  ContentView.swift
//  TestingReports
//
//  Created by Paul Ancajima on 4/22/23.
//

import SwiftUI
import Realm
import RealmSwift

let app = App(id: "testingreports-wmsrv")
let anonymousCredentials = Credentials.anonymous

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .onAppear {
            print("fetch some data")
            app.login(credentials: anonymousCredentials) { (result) in
                switch result {
                case .failure(let error):
                    print("Login failed: \(error.localizedDescription)")
                case .success(let user):
                    print("Successfully logged in as user \(user)")
                    
                    let client = app.currentUser!.mongoClient("mongodb-atlas")
                    
                    let database = client.database(named: "testing_database")
                    
                    let collection = database.collection(withName: "code_coverage")
                    
                    let queryFilter: Document = ["appName": "innovation041023.app"]
                    
                    collection.find(filter: queryFilter) { result in
                        switch result {
                        case .failure(let error):
                            print("Call to MongoDB failed: \(error.localizedDescription)")
                            return
                        case .success(let documents):
                            print("Results: ")
                            for document in documents {
                                // Access document fields using their keys
                                let appName = document["appName"]??.stringValue ?? ""
                                let uuid = document["uuid"]??.stringValue ?? ""
                                let filenames = (document["filenames"] as? AnyBSON)?.arrayValue
                                let linesCovered = Int(document["linesCovered"]??.int32Value ?? 0)
                                let totalLines = Int(document["totalLines"]??.int32Value ?? 0)
                                let timestamp: Date? = {
                                    if let datetime = document["timestamp"] as? AnyBSON, case let .datetime(date) = datetime {
                                        return date
                                    } else {
                                        return nil
                                    }
                                }()
                                
                                // Create instances of CodeCoverage class with document field values
                                let codeCoverage = CodeCoverage()
                                codeCoverage.appName = appName
                                codeCoverage.uuid = uuid
                                // Iterate through filenames array and create instances of File class
                                for filenameDocument in filenames ?? [] {
                                    let file = File()
                                    file.name = filenameDocument?.documentValue?["name"]??.stringValue ?? ""
                                    file.uuid = filenameDocument?.documentValue?["uuid"]??.stringValue ?? ""
                                    file.linesCovered = Int(filenameDocument?.documentValue?["linesCovered"]??.int32Value ?? 0)
                                    file.totalLines = Int(filenameDocument?.documentValue?["totalLines"]??.int32Value ?? 0)
                                    // Append File instances to filenames array
                                    codeCoverage.filenames.append(file)
                                }
                                codeCoverage.linesCovered = linesCovered
                                codeCoverage.totalLines = totalLines
                                codeCoverage.timestamp = timestamp
                                
                                // Access the created instances of CodeCoverage class
                                print("App Code Coverage: \(codeCoverage)")
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class CodeCoverage: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var appName: String = ""
    @objc dynamic var uuid: String = ""
    let filenames = RealmSwift.List<File>()
    @objc dynamic var linesCovered: Int = 0
    @objc dynamic var totalLines: Int = 0
    @objc dynamic var timestamp: Date?
}

class File: EmbeddedObject {
    @objc dynamic var name: String = ""
    @objc dynamic var uuid: String = ""
    @objc dynamic var linesCovered: Int = 0
    @objc dynamic var totalLines: Int = 0
}
