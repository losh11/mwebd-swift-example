import SwiftUI
import GRPCCore
import Mwebd
import BitcoinKit
import NIO
import NIOConcurrencyHelpers

struct ContentView: View {
    @State private var server: MwebdServer?
    @State private var errorMessage: String?
    @State private var generatedAddresses: [String] = []
    private var port: Int?
    
    var body: some View {
        VStack {
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    startMwebd()
                }
            }) {
                Text("Start Mwebd")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: generateAddresses) {
                Text("Generate Addresses")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            List(generatedAddresses, id: \.self) { address in
                Text(address)
            }
            
            Button(action: {
                Task {
                    await getStatus()
                }
            }) {
                Text("Get Status")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    func startMwebd() {
        stopServer()
        
        let args = MwebdServerArgs()
        args.chain = "mainnet"
        args.dataDir = getDocumentsDirectory().path
        args.peerAddr = "88.198.50.4:9333"
        args.proxyAddr = ""
        
        var error: NSError?
        guard let newServer = MwebdNewServer2(args, &error) else {
            errorMessage = error?.localizedDescription ?? "Unknown error"
            return
        }
        
        server = newServer
        var port: Int = 0
    
        do {
            _ = try server?.start(9332, ret0_: &port)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopServer() {
        server?.stop()
    }
    
    func generateAddresses() {
        guard let mnemonic = try? Mnemonic.generate() else {
            DispatchQueue.main.async {
                errorMessage = "Failed to generate mnemonic"
            }
            return
        }
        
        guard let seed = try? Mnemonic.seed(mnemonic: mnemonic) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to get seed"
            }
            return
        }
        
        let network = Network.mainnetBTC
        let account = 0
        let externalIndex: UInt32 = 1000
        let internalIndex: UInt32 = 2

        let wallet = try? HDWallet(seed: seed, externalIndex: externalIndex, internalIndex: internalIndex, network: network, account: UInt32(account))

        guard let scanKey = wallet?.privKey(index: 0, chain: .external) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to derive scan key"
            }
            return
        }

        guard let spendKey = wallet?.privKey(index: 1, chain: .external) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to derive spend key"
            }
            return
        }

        let scanSecret = scanKey.data
        let spendPubKey = spendKey.publicKey().data
        
        var addresses: [String] = []
        let address = MwebdAddresses(scanSecret, spendPubKey, Int32(0), Int32(1))
        addresses.append(address)
        
        generatedAddresses = addresses
    }
    
    func getStatus() async {
        let client = MwebClient(host: "127.0.0.1", port: 9332)
        
        do {
            let status = try await client.getStatus()
            print("Connected to MWEBD: Block height = \(status)")
        } catch {
            print("Error: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

#Preview {
    ContentView()
}
