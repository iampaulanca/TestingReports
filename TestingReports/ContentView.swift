//
//  ContentView.swift
//  TestingReports
//
//  Created by Paul Ancajima on 4/22/23.
//

import SwiftUI
import Realm
import RealmSwift
import Charts

let app = App(id: "testingreports-wmsrv")
let anonymousCredentials = Credentials.anonymous

struct PlotXY: Identifiable, Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    let x: Date
    let y: Double
    let id = UUID()
}
import Combine
@MainActor class TestingReportViewModel: ObservableObject {
    @Published var appCodeCoverage: AppCodeCoverage
    var cancellables = Set<AnyCancellable>()
    @Published var appnames: [String] = []
    
    init(appCodeCoverage: AppCodeCoverage = AppCodeCoverage()) {
        self.appCodeCoverage = appCodeCoverage
        appCodeCoverage.$appCodeCoverage.sink { [weak self] value in
            Task { @MainActor in
                self?.appnames.append(value.keys.first ?? "NA")
            }
        }.store(in: &cancellables)
//        for _ in 1...10 {
//            let codeCoverage = CodeCoverage()
//            codeCoverage._id = ObjectId.generate()
//            codeCoverage.appName = "innovation041023.app"
//            codeCoverage.uuid = UUID().uuidString
//            let year = Int.random(in: 2021...2023) // Generate a random year between 2021 and 2023
//            let month = Int.random(in: 1...12) // Generate a random month between 1 and 12
//            let day = Int.random(in: 1...31) // Generate a random day between 1 and 31
//            codeCoverage.timestamp = createDate(year: year, month: month, day: day)
//
//            let file1 = File()
//            file1.name = "StockDetailView.swift"
//            file1.uuid = UUID().uuidString
//            file1.linesCovered = Int.random(in: 40...60) // Generate a random value between 40 and 60 for linesCovered
//            file1.totalLines = 423
//
//            let file2 = File()
//            file2.name = "AddStockView.swift"
//            file2.uuid = UUID().uuidString
//            file2.linesCovered = Int.random(in: 25...35) // Generate a random value between 25 and 35 for linesCovered
//            file2.totalLines = 123
//
//            codeCoverage.filenames.append(objectsIn: [file1, file2])
//            codeCoverage.linesCovered = file1.linesCovered + file2.linesCovered
//
//            appCodeCoverage.appCodeCoverage[codeCoverage.appName, default: []].append(codeCoverage)
//        }
    }
    func insertCodeCoverage(appName: String, coverageReport: CodeCoverage) {
        self.appCodeCoverage.appCodeCoverage[appName, default: []].append(coverageReport)
    }
    
    func createDate(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // Generate random hour (0-23), minute (0-59), and second (0-59)
        components.hour = Int.random(in: 0...23)
        components.minute = Int.random(in: 0...59)
        components.second = Int.random(in: 0...59)
        
        return calendar.date(from: components) ?? Date()
    }
    
}

enum Navigation: Hashable {
    case app([CodeCoverage])
    case report(CodeCoverage)
}

struct CodeCoverageSpecificReportDetailView: View {
    var coverageReport: CodeCoverage = CodeCoverage()
    var body: some View {
        VStack {
            List {
                ForEach(coverageReport.filenames, id: \.uuid) { report in
                    VStack(alignment: .leading) {
                        Text("File: \(report.name)")
                        Text("lines covered: \(report.linesCovered)")
                        Text("total covered: \(report.totalLines)")
                        Text("percentage: \(Int(Double(report.linesCovered) / Double(report.totalLines) * 100))%")
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct CodeCoverageReportDetailView: View {
    var coverageReports: [CodeCoverage] = []
    init(coverageReports: [CodeCoverage]) {
        self.coverageReports = coverageReports
    }
    var body: some View {
        VStack {
            List {
                ForEach(coverageReports, id: \._id) { report in
                    NavigationLink(value: Navigation.report(report)) {
                        Text(report.appName + " - " + (report.timestamp != nil ? DateFormatter.localizedString(from: report.timestamp!, dateStyle: .short, timeStyle: .short) : ""))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ContentView: View {
    @StateObject var testingReportViewModel = TestingReportViewModel()
    @State var navigationPath = NavigationPath()
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                List {
                    ForEach(testingReportViewModel.appCodeCoverage.appCodeCoverage.keys.map{$0}, id: \.self) { appName in
                        NavigationLink(value: Navigation.app(testingReportViewModel.appCodeCoverage.appCodeCoverage[appName, default: []])) {
                            Text(appName)
                        }
                    }
                }
                .navigationDestination(for: Navigation.self) { navigation in
                    switch navigation {
                    case let .app(coverageReports):
                        CodeCoverageReportDetailView(coverageReports: coverageReports.sorted(by: {$0.timestamp ?? Date() < $1.timestamp ?? Date() }))
                    case let .report(coverageReport):
                        CodeCoverageSpecificReportDetailView(coverageReport: coverageReport)
                    }
                }
                .frame(maxWidth: .infinity)
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
                                    let id: ObjectId? = {
                                        if let idValue = document["_id"] as? AnyBSON, case let .objectId(objectId) = idValue {
                                            return objectId
                                        } else {
                                            return nil
                                        }
                                    }()

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
                                    codeCoverage._id = id ?? ObjectId()
                                    codeCoverage.uuid = uuid
                                    codeCoverage.linesCovered = linesCovered
                                    codeCoverage.totalLines = totalLines
                                    codeCoverage.timestamp = timestamp

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

                                    self.testingReportViewModel.insertCodeCoverage(appName: appName, coverageReport: codeCoverage)
                                }
                                print(testingReportViewModel.appCodeCoverage.appCodeCoverage)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class AppCodeCoverage: ObservableObject, Identifiable {
    let uuid = UUID()
    @Published var appCodeCoverage = [String: [CodeCoverage]]()
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
