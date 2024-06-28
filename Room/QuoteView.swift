import SwiftUI

struct QuoteView: View {
    var quote: String
    var isTidy: Bool

    var body: some View {
        VStack {
            Text(quote)
                .font(.title)
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTidy ? Color.green : Color.red)
        .edgesIgnoringSafeArea(.all)
    }
}
