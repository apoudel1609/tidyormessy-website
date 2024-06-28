import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RoomViewModel()
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isQuotePresented = false
    @State private var isProcessing = false
    @State private var isCameraViewPresented = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                // Add your logo image at the top
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200) // Adjust the size as needed
                
                Spacer()
                
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    } else {
                        Text("No Image Selected")
                            .foregroundColor(.gray)
                            .frame(width: 200, height: 200)
                            .background(Color.gray.opacity(0.2))
                    }
                    
                    if let result = viewModel.predictionResult {
                        Text("Prediction: \(result)")
                            .font(.title)
                            .padding()
                            .foregroundColor(result == "Tidy" ? .green : .red)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding(8)
                    }
                }
                
                Spacer()
                
                Button("Select Image") {
                    selectedImage = nil
                    viewModel.predictionResult = nil
                    isImagePickerPresented = true
                }
                .padding()
                
                Button("Take Picture") {
                    selectedImage = nil
                    viewModel.predictionResult = nil
                    isCameraViewPresented = true
                }
                .padding()
                
                Button("Predict") {
                    if let image = selectedImage {
                        isProcessing = true  // Start processing
                        viewModel.predict(image: image) {
                            isProcessing = false  // Stop processing when done
                        }
                    } else {
                        print("No image selected")
                    }
                }
                .padding()
                
                Spacer()
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }
            .fullScreenCover(isPresented: $isCameraViewPresented) {
                CameraView(image: $selectedImage)
            }
            .sheet(isPresented: $isQuotePresented) {
                if let quote = viewModel.quote {
                    QuoteView(quote: quote, isTidy: viewModel.predictionResult == "Tidy")
                }
            }
            .onChange(of: viewModel.quote) { newValue in
                if let newValue = newValue {
                    print("Quote updated: \(newValue)")
                    isQuotePresented = true
                    print("Quote sheet presented")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isQuotePresented = false
                        print("Quote sheet dismissed")
                    }
                }
            }
            
            if isProcessing {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2) // Adjust size as needed
                        .padding(.bottom, 20)
                    
                    Text("Processing...")
                        .font(.title)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
                .edgesIgnoringSafeArea(.all)
                .disabled(true) // Disable interactions
            }
        }
    }
}
