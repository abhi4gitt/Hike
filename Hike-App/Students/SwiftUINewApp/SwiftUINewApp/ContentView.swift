
import SwiftUI
import Vision
import Charts

// ViewModel for JSON Extraction & Chart Data
class TextExtractor: ObservableObject {
    @Published var extractedJSON: String = ""
    @Published var timeSeries: [TimeSeriesData] = []
    
    @Published var selectedDataPoint: TimeSeriesData?
    
    func extractText(from imageName: String) {
        guard let image = UIImage(named: imageName),
              let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let extractedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let rawText = extractedStrings.joined(separator: " ")
            
            DispatchQueue.main.async {
                self.extractedJSON = self.cleanAndFormatJSON(from: rawText)
                self.parseJSONData()
            }
        }
        
        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Error recognizing text: \(error)")
            }
        }
    }
    
    private func cleanAndFormatJSON(from text: String) -> String {
        var cleanedText = text
            .replacingOccurrences(of: "I", with: "")
            .replacingOccurrences(of: "'", with: "\"")
            .replacingOccurrences(of: "}{", with: "}, {")
            .replacingOccurrences(of: "\"\"", with: "\", \"")
            .replacingOccurrences(of: "{, ", with: "{")
            .replacingOccurrences(of: ", {", with: "{")
            .replacingOccurrences(of: "} {", with: "}, {")
        
        if !cleanedText.contains("[") {
            cleanedText = cleanedText.replacingOccurrences(of: "\"time_series\":{", with: "\"time_series\":[{")
        }
        cleanedText = cleanedText.replacingOccurrences(of: "}]", with: "}]}")
        
        cleanedText = extractTimeSeriesData(cleanedText)
        
        if let jsonData = cleanedText.data(using: .utf8) {
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                let formattedJSONData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                return String(data: formattedJSONData, encoding: .utf8) ?? "Invalid JSON"
            } catch {
                return "JSON Parsing Error: \(error.localizedDescription)"
            }
        }
        
        return "Invalid JSON Format"
    }
    
    private func extractTimeSeriesData(_ text: String) -> String {
        guard text.contains("\"time_series\"") else { return text }
        
        let timestampPattern = "\"timestamp\":\\s*\"([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z)\""
        let valuePattern = "\"value\":\\s*([0-9.]+)"
        
        let timestampRegex = try? NSRegularExpression(pattern: timestampPattern, options: [])
        let valueRegex = try? NSRegularExpression(pattern: valuePattern, options: [])
        
        var timestamps: [String] = []
        if let matches = timestampRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    timestamps.append(String(text[range]))
                }
            }
        }
        
        var values: [String] = []
        if let matches = valueRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) {
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    values.append(String(text[range]))
                }
            }
        }
        
        let entryCount = min(timestamps.count, values.count)
        var timeSeriesEntries: [(timestamp: String, value: String)] = []
        
        for i in 0..<entryCount {
            timeSeriesEntries.append((timestamps[i], values[i]))
        }
        
        var result = "{\n    \"time_series\": [\n"
        for (index, entry) in timeSeriesEntries.enumerated() {
            result += "        {\"timestamp\": \"\(entry.timestamp)\", \"value\": \(entry.value)}"
            if index < timeSeriesEntries.count - 1 {
                result += ",\n"
            } else {
                result += "\n"
            }
        }
        result += "    ]\n}"
        
        return result
    }
    
    func parseJSONData() {
        guard let jsonData = extractedJSON.data(using: .utf8) else { return }
        do {
            let decodedData = try JSONDecoder().decode(TimeSeriesWrapper.self, from: jsonData)
            let formatter = ISO8601DateFormatter()
            self.timeSeries = decodedData.time_series.compactMap { entry in
                guard let date = formatter.date(from: entry.timestamp) else { return nil }
                return TimeSeriesData(timestamp: date, value: entry.value)
            }
        } catch {
            print("JSON Parsing Error: \(error)")
        }
    }
}

// Data Models
struct TimeSeriesWrapper: Codable {
    let time_series: [TimeSeriesEntry]
}

struct TimeSeriesEntry: Codable {
    let timestamp: String
    let value: Double
}

struct TimeSeriesData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// SwiftUI Line Chart with Tooltips
struct TimeSeriesChartView: View {
    @StateObject private var extractor = TextExtractor()
    @State private var selectedXPosition: Double?
    
    var body: some View {
        VStack {
            Text("Extracted JSON Data:")
                .font(.headline)
                .padding()
            
            ScrollView {
                Text(extractor.extractedJSON)
                    .padding()
                    .foregroundColor(.blue)
            }
            .frame(height: 200)
            
            Button("Extract & Visualize JSON") {
                extractor.extractText(from: "time_series_report")
            }
            .padding()
            
            Text("Time-Series Data Visualization")
                .font(.headline)
                .padding()
            
            // Chart with proper selection handling
            Chart(extractor.timeSeries) { data in
                LineMark(
                    x: .value("Time", data.timestamp),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(.blue)
                
                // Add point marks to make data points more visible
                PointMark(
                    x: .value("Time", data.timestamp),
                    y: .value("Value", data.value)
                )
                .foregroundStyle(.blue)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPosition = value.location.x
                                    let domainValue = proxy.value(atX: xPosition, as: Date.self)
                                    
                                    if let date = domainValue {
                                        
                                        // Find the closest data point
                                        if let closestDataPoint = findClosestDataPoint(to: date) {
                                            extractor.selectedDataPoint = closestDataPoint
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 300)
            .padding()
            
            if let selectedData = extractor.selectedDataPoint {
                Text("Timestamp: \(formattedDate(selectedData.timestamp))\nValue: \(selectedData.value, specifier: "%.2f")")
                    .frame(height: 60)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            Spacer()
                .frame(height: 100)
        }
    }
    
    // Helper function to format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to find the closest data point to a given date
    private func findClosestDataPoint(to date: Date) -> TimeSeriesData? {
        guard !extractor.timeSeries.isEmpty else { return nil }
        
        return extractor.timeSeries.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
    }
}

#Preview {
    TimeSeriesChartView()
}

@main
struct TimeSeriesChartApp: App {
    var body: some Scene {
        WindowGroup {
            TimeSeriesChartView()
        }
    }
}

// **output:** - OK
