import SwiftUI
import Mwebd

@main
struct MwebdApp: App {
    @State private var hasWallet: Bool = false
    @State private var walletMnemonic: [String] = []
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                Group {
                    if hasWallet {
                        ContentView(walletMnemonic: walletMnemonic)
                    } else {
                        CreateView(onWalletCreated: { mnemonic in
                            walletMnemonic = mnemonic
                            hasWallet = true
                        })
                    }
                }
            }
        }
    }
}
