import SwiftUI
import UIKit

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        RootTabBarController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
#Preview {
    ContentView()
        .ignoresSafeArea()
}
