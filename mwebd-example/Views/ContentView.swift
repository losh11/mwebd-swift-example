import SwiftUI
import GRPCCore
import Mwebd
import BitcoinKit
import NIO
import NIOConcurrencyHelpers

struct ContentView: View {
    @State private var server: MwebdServer?
    @State private var scanKey: PrivateKey?
    @State private var spendKey: PrivateKey?
    @State private var errorMessage: String?
    @State private var generatedAddresses: [String] = []
    private var port: Int?
    
    @State private var showingAlert = false
    @State private var statusMessage = ""
    
    var walletMnemonic: [String]
    init(walletMnemonic: [String] = []) {
        self.walletMnemonic = walletMnemonic
    }
    
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
            
            List {
                ForEach(generatedAddresses, id: \.self) { address in
                    Text(address)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .listStyle(PlainListStyle())
            .environment(\.defaultMinListRowHeight, 44)
            
            Button(action: {
                Task {
                    let status = await getStatus()
                    statusMessage =  "Block Height: " + String(status.blockHeaderHeight) + "\nMwebHeader Height: " + String(status.mwebHeaderHeight) + "\nMwebUtxo Height: " + String(status.mwebUtxosHeight)
                }
                showingAlert = true
            }) {
                Text("Get Status")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }.alert(statusMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            
            Button(action: {
                Task {
                    await mwebUtxos()
                }
            }) {
                Text("Get Utxos")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    func startMwebd() {
        DispatchQueue.global(qos: .background).async {
            stopServer()
            
            let args = MwebdServerArgs()
            args.chain = "mainnet"
            args.dataDir = getDocumentsDirectory().path
            args.peerAddr = "88.198.50.4:9333"
            args.proxyAddr = ""
            
            var error: NSError?
            guard let newServer = MwebdNewServer2(args, &error) else {
                DispatchQueue.main.async {
                    errorMessage = error?.localizedDescription ?? "Unknown error"
                }
                return
            }
            
            server = newServer
            var port: Int = 0
            
            do {
                _ = try server?.start(9332, ret0_: &port)
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func stopServer() {
        server?.stop()
    }
    
    func generateWallet() {
        guard !walletMnemonic.isEmpty else {
            DispatchQueue.main.async {
                errorMessage = "No mnemonic available"
            }
            return
        }
        
        guard let seed = try? Mnemonic.seed(mnemonic: walletMnemonic) else {
            DispatchQueue.main.async {
                errorMessage = "Failed to get seed from provided mnemonic"
            }
            return
        }
        
        let network = Network.mainnetBTC
        let account = 0
        let externalIndex: UInt32 = 1000
        let internalIndex: UInt32 = 2

        let wallet = HDWallet.init(seed: seed,
                                   externalIndex: externalIndex,
                                   internalIndex: internalIndex,
                                   network: network,
                                   account: UInt32(account))
        
        print("finished wallet")
        
        let scan = wallet.privKey(index: 0, chain: .external)
        let spend = wallet.privKey(index: 1, chain: .external)
        
        scanKey = scan
        spendKey = spend
        
        DispatchQueue.main.async {
            errorMessage = nil
        }
    }
    func generateAddresses() {
        generateWallet()
        print("generated wallet")

        guard let scanKey = scanKey, let spendKey = spendKey else {
            DispatchQueue.main.async {
                errorMessage = "Scan or spend key not initialized. Generate wallet first."
            }
            return
        }
        
        // Get the data from the keys
        let scanSecret = scanKey.data
        let spendPubKey = spendKey.publicKey().data
        
        // Generate the address
        let address = MwebdAddresses(scanSecret, spendPubKey, Int32(0), Int32(20))
        
        let addressArray = address.components(separatedBy: ",")
        
        DispatchQueue.main.async {
            generatedAddresses = addressArray
            errorMessage = nil // Clear any previous errors
        }
    }
    
    func getStatus() async -> StatusResponse {
        let client = MwebClient(host: "127.0.0.1", port: 9332)
        
        do {
            let status = try await client.getStatus()
            print("Connected to MWEBD: Block height = \(status.blockHeaderHeight)")
            return status
        } catch {
            print("Error: \(error)")
            return StatusResponse()
        }
    }
    
    func mwebUtxos() async {
        let client = MwebClient(host: "127.0.0.1", port: 9332)
        
        guard let scanSecret = scanKey?.data else {
            DispatchQueue.main.async {
                errorMessage = "Scan key not initialized. Generate wallet first."
            }
            return
        }

        do {
            print(scanSecret.hex)
            let utxo = try await client.getUtxos(fromHeight: Int32(2868891), scanSecret: scanSecret)
            print(utxo[0])
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
