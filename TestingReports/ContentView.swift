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

class TestingReportViewModel: ObservableObject {
    @Published var codeCoverages = [CodeCoverage]()
    
    init(codeCoverages: [CodeCoverage] = [CodeCoverage]()) {
        self.codeCoverages = codeCoverages
        
        let codeCoverage1 = CodeCoverage()
        codeCoverage1._id = ObjectId.generate()
        codeCoverage1.appName = "innovation041023.app"
        codeCoverage1.uuid = UUID().uuidString
        codeCoverage1.timestamp = Date()

        let file1 = File()
        file1.name = "StockDetailView.swift"
        file1.uuid = UUID().uuidString
        file1.linesCovered = 50
        file1.totalLines = 423

        let file2 = File()
        file2.name = "AddStockView.swift"
        file2.uuid = UUID().uuidString
        file2.linesCovered = 30
        file2.totalLines = 123
        codeCoverage1.filenames.append(objectsIn: [file1, file2])
        codeCoverage1.linesCovered = file1.linesCovered + file2.linesCovered
        self.codeCoverages.append(codeCoverage1)
    }
}

struct ContentView: View {
    var testingReportViewModel = TestingReportViewModel()
    
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
                    
//                    let queryFilter: Document = ["appName": "innovation041023.app"]
//
//                    collection.find(filter: queryFilter) { result in
//                        switch result {
//                        case .failure(let error):
//                            print("Call to MongoDB failed: \(error.localizedDescription)")
//                            return
//                        case .success(let documents):
//                            print("Results: ")
//                            for document in documents {
//                                // Access document fields using their keys
//                                let appName = document["appName"]??.stringValue ?? ""
//                                let id: ObjectId? = {
//                                    if let idValue = document["_id"] as? AnyBSON, case let .objectId(objectId) = idValue {
//                                        return objectId
//                                    } else {
//                                        return nil
//                                    }
//                                }()
//
//                                let uuid = document["uuid"]??.stringValue ?? ""
//                                let filenames = (document["filenames"] as? AnyBSON)?.arrayValue
//                                let linesCovered = Int(document["linesCovered"]??.int32Value ?? 0)
//                                let totalLines = Int(document["totalLines"]??.int32Value ?? 0)
//                                let timestamp: Date? = {
//                                    if let datetime = document["timestamp"] as? AnyBSON, case let .datetime(date) = datetime {
//                                        return date
//                                    } else {
//                                        return nil
//                                    }
//                                }()
//
//                                // Create instances of CodeCoverage class with document field values
//                                let codeCoverage = CodeCoverage()
//                                codeCoverage.appName = appName
//                                codeCoverage._id = id ?? ObjectId()
//                                codeCoverage.uuid = uuid
//                                codeCoverage.linesCovered = linesCovered
//                                codeCoverage.totalLines = totalLines
//                                codeCoverage.timestamp = timestamp
//
//                                // Iterate through filenames array and create instances of File class
//                                for filenameDocument in filenames ?? [] {
//                                    let file = File()
//                                    file.name = filenameDocument?.documentValue?["name"]??.stringValue ?? ""
//                                    file.uuid = filenameDocument?.documentValue?["uuid"]??.stringValue ?? ""
//                                    file.linesCovered = Int(filenameDocument?.documentValue?["linesCovered"]??.int32Value ?? 0)
//                                    file.totalLines = Int(filenameDocument?.documentValue?["totalLines"]??.int32Value ?? 0)
//                                    // Append File instances to filenames array
//                                    codeCoverage.filenames.append(file)
//                                }
//
//
//                                testingReportViewModel.codeCoverages.append(codeCoverage)
//                            }
                            print(testingReportViewModel.codeCoverages)
//                        }
//                    }
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
    @objc dynamic var _id: ObjectId?
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
