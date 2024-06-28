import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image)
    }

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        @Binding var image: UIImage?

        init(image: Binding<UIImage?>) {
            _image = image
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(), error == nil else {
                return
            }

            let capturedImage = UIImage(data: data)
            DispatchQueue.main.async {
                self.image = capturedImage
                // Dismiss the camera view after capturing the photo
                if let topController = UIApplication.shared.windows.first?.rootViewController {
                    topController.dismiss(animated: true, completion: nil)
                }
            }

            // Call your image processing function here
            if let capturedImage = capturedImage {
                processImage(capturedImage)
            }
        }

        func processImage(_ image: UIImage) {
            guard let url = URL(string: "https://tidyormessy.com/predict") else {
                print("Invalid URL")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                print("Failed to convert image to data")
                return
            }

            var body = Data()
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n--\(boundary)--\r\n")
            request.httpBody = body

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                                // Update your UI with the prediction and quote
                                print("Prediction Result: \(prediction)")
                                print("Quote: \(quote)")
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
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCapturePhotoCaptureDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        requestCameraPermission()
    }

    func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCameraSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.startCameraSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlertForSettings()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showAlertForSettings()
            }
        @unknown default:
            break
        }
    }

    func startCameraSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession = AVCaptureSession()
            self.captureSession.sessionPreset = .photo

            guard let backCamera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: backCamera) else {
                return
            }

            self.captureSession.addInput(input)

            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput.isHighResolutionCaptureEnabled = true
            self.captureSession.addOutput(self.photoOutput)

            DispatchQueue.main.async {
                if let connection = self.photoOutput.connection(with: .video) {
                    connection.videoOrientation = .portrait
                }

                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.videoGravity = .resizeAspectFill
                self.previewLayer.frame = self.view.bounds
                self.view.layer.addSublayer(self.previewLayer)

                self.captureSession.startRunning()

                self.setupCaptureButton()
            }
        }
    }

    func setupCaptureButton() {
        let captureButton = UIButton(type: .system)
        captureButton.setTitle("Capture", for: .normal)
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        captureButton.layer.cornerRadius = 25
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

        view.addSubview(captureButton)

        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 100),
            captureButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func showAlertForSettings() {
        let alert = UIAlertController(title: "Camera Access Required", message: "Please enable camera access in settings to use this feature.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        })
        present(alert, animated: true, completion: nil)
    }

    @objc func capturePhoto() {
        guard let delegate = delegate else {
            return
        }
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
}
