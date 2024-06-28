import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

class RoomViewModel: ObservableObject {
    @Published var predictionResult: String? = nil
    @Published var quote: String? = nil

    func predict(image: UIImage, completion: @escaping () -> Void) {  // Add completion handler
        guard let url = URL(string: "https://tidyormessy.com/predict") else {
            print("Invalid URL")
            completion()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            completion()
            return
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async {
                    completion()  // Call completion when done
                }
            }
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("Parsed JSON: \(json)")  // Debug print statement
                    if let prediction = json["prediction"] as? String, // assuming it is a string
                       let quote = json["quote"] as? String {
                        DispatchQueue.main.async {
                            self?.predictionResult = prediction
                            self?.quote = quote
                            print("Prediction Result: \(self?.predictionResult ?? "")")
                            print("Quote: \(self?.quote ?? "")")
                        }
                    } else {
                        print("Failed to parse prediction or quote from JSON")
                    }
                } else {
                    print("Failed to parse JSON")
                }
            } catch {
                print("JSON Error: \(error)")
            }
        }
        task.resume()
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
