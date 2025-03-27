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
    @State private var utxos: [Utxo] = []
    @State private var isLoadingUtxos = false
    @State private var showingAlert = false
    @State private var statusMessage = ""
    @State private var isAddressesSectionExpanded = false
    @State private var navigateToCreateTransaction = false
    private var port: Int?
    
    var walletMnemonic: [String]
    init(walletMnemonic: [String] = []) {
        self.walletMnemonic = walletMnemonic
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Buttons section
                HStack(spacing: 12) {
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
                }
                
                if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // UTXOs Section - Always show if there are UTXOs
                if !utxos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                        Text("MWEB UTXOs")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(utxos.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    // UTXO balance summary
                    VStack(spacing: 12) {
                        // Total balance with gradient background
                        VStack(spacing: 4) {
                            Text("Total Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatAmount(totalBalance))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        
                        // Confirmed and Unconfirmed in two cards side by side
                        HStack(spacing: 12) {
                            // Confirmed Balance
                            VStack(spacing: 4) {
                                Text("Confirmed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(formatAmount(confirmedBalance))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(8)
                            
                            // Unconfirmed Balance
                            VStack(spacing: 4) {
                                Text("Unconfirmed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(formatAmount(unconfirmedBalance))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 12)
                        
                        // UTXO list
                        VStack {
                            ForEach(utxos, id: \.outputID) { utxo in
                                UtxoListItem(utxo: utxo)
                                Divider()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                // Addresses Section - Always visible with collapsible content
                VStack(alignment: .leading, spacing: 8) {
                    // Collapsible header
                    Button(action: {
                        withAnimation {
                            isAddressesSectionExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("MWEB Addresses")
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: isAddressesSectionExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Collapsible content
                    if isAddressesSectionExpanded {
                        if generatedAddresses.isEmpty {
                            Text("No addresses available. Click 'Generate Addresses' button to create new addresses.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(generatedAddresses, id: \.self) { address in
                                    AddressListItem(address: address)
                                    Divider()
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Action buttons
                HStack(spacing: 20) {
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
                            await streamUtxos()
                        }
                    }) {
                        HStack {
                            Text("Stream Utxos")
                            if isLoadingUtxos {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoadingUtxos)
                    
                    
                    NavigationLink(
                        destination: CreateTransactionView(
                            scanKey: scanKey,
                            spendKey: spendKey,
                            utxos: utxos
                        ),
                        isActive: $navigateToCreateTransaction
                    ) {
                        Button(action: {
                            navigateToCreateTransaction = true
                        }) {
                            Text("Create Transaction")
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(utxos.isEmpty || scanKey == nil || spendKey == nil)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("MWEB Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-expand the addresses section on first load if there are addresses
            isAddressesSectionExpanded = !generatedAddresses.isEmpty
        }
    }
    
    // MARK: - Balance Calculations
    
    private var confirmedBalance: UInt64 {
        utxos.filter { $0.height > 0 }.reduce(0) { $0 + $1.value }
    }
    
    private var unconfirmedBalance: UInt64 {
        utxos.filter { $0.height == 0 }.reduce(0) { $0 + $1.value }
    }
    
    private var totalBalance: UInt64 {
        confirmedBalance + unconfirmedBalance
    }
    
    private func formatAmount(_ value: UInt64) -> String {
        let ltcValue = Double(value) / 100_000_000.0
        return String(format: "%.8f LTC", ltcValue)
    }
    
    
/// startMwebd() creates a grpc server in the background.
/// user specifies arguements
    func startMwebd() {
        DispatchQueue.global(qos: .background).async {
            stopServer()
            
            let args = MwebdServerArgs()
            args.chain = "mainnet"
            args.dataDir = getDocumentsDirectory().path
            // peer must support NODE_MWEB_LIGHT_CLIENT
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
    
/// generateWallet() creates a random HD wallet
///
/// When integrating MWEBD into your own application, generate scanKeys and
/// spendKeys from the same non-MWEB mnemonic
/// scanKeys must be derived with path: m/1000'/2'/0'/0'
/// spendKeys must be derived with path: m/1000'/2'/0'/1'
///
/// NOTE: example code below uses the incorrect derivation paths!
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
        
        let scan = wallet.privKey(index: 0, chain: .external)
        let spend = wallet.privKey(index: 1, chain: .external)
        
        scanKey = scan
        spendKey = spend
        
        DispatchQueue.main.async {
            errorMessage = nil
        }
    }
    
/// generateAddresses() uses a scanKey & spendKey to generate many addresses
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
            
            isAddressesSectionExpanded = true
        }
    }
    
/// getStatus() responds with current MWEBD blockchain state
///
/// Use to check if the wallet is synced and ready to send funds
/// Compare with another source of current tip height to calculate sync %
/// MWEB utxo height must match tip block header height for completed sync
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
    
/// streamUtxos() is a grpc stream which scans for new utxos to the wallet
///
/// stream should ideally be opened and kept open after mwebd grpc server is started
    func streamUtxos() async {
        let client = MwebClient(host: "127.0.0.1", port: 9332)
        
        guard let scanSecret = scanKey?.data else {
            await MainActor.run {
                errorMessage = "Scan key not initialized. Generate wallet first."
            }
            return
        }

        do {
            // Clear existing UTXOs before starting a new stream
            await MainActor.run {
                utxos = []
                isLoadingUtxos = true
                errorMessage = nil
            }
            
            try await client.streamUtxos(fromHeight: Int32(2868900), scanSecret: scanSecret) { newUtxo in
                let ltcAmount = Double(newUtxo.value) / 100_000_000.0
                print("Received UTXO: \(newUtxo.outputID) - Amount: \(newUtxo.value) satoshis (\(String(format: "%.8f", ltcAmount)) LTC)")
                
                // Update UI on the main thread
                Task { @MainActor in
                    // Check if this UTXO is already in our list by output ID
                    if !utxos.contains(where: { $0.outputID == newUtxo.outputID }) {
                        utxos.append(newUtxo)
                    }
                }
            }
            
            // This code will run after streaming completes (if it ever does)
            await MainActor.run {
                isLoadingUtxos = false
                if utxos.isEmpty {
                    errorMessage = "No UTXOs found"
                }
            }
        } catch {
            print("Error in UTXO stream: \(error)")
            await MainActor.run {
                errorMessage = "Failed to stream UTXOs: \(error.localizedDescription)"
                isLoadingUtxos = false
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// UTXO List Item View
struct UtxoListItem: View {
    let utxo: Utxo
    @State private var isCopied = false
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Output ID and amount
            HStack {
                Text(truncatedOutputId)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formattedAmount)
                    .font(.headline)
            }
            
            // Address
            Text(utxo.address)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Status and date
            HStack {
                Text(confirmationStatus)
                    .font(.caption)
                    .foregroundColor(utxo.height > 0 ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(utxo.height > 0 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    )
                
                Spacer()
                
                if utxo.blockTime > 0 {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            UIPasteboard.general.string = utxo.outputID
            withAnimation {
                isCopied = true
            }
            
            // Show a temporary alert
            showCopiedAlert = true
            
            // Reset copied indicator after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCopied = false
                }
            }
        }
        .alert("Output ID Copied", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The UTXO ID has been copied to your clipboard.")
        }
    }
    
    // Formatted properties
    private var truncatedOutputId: String {
        let id = utxo.outputID
        if id.count > 14 {
            let prefix = String(id.prefix(7))
            let suffix = String(id.suffix(7))
            return "\(prefix)...\(suffix)"
        }
        return id
    }
    
    private var formattedAmount: String {
        let ltcValue = Double(utxo.value) / 100_000_000.0
        return String(format: "%.8f LTC", ltcValue)
    }
    
    private var confirmationStatus: String {
        utxo.height > 0 ? "Confirmed" : "Pending"
    }
    
    private var formattedDate: String {
        if utxo.blockTime == 0 {
            return ""
        }
        
        let date = Date(timeIntervalSince1970: TimeInterval(utxo.blockTime))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddressListItem: View {
    let address: String
    @State private var isCopied = false
    @State private var showCopiedAlert = false
    
    var body: some View {
        HStack {
            Text(address)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            if isCopied {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            UIPasteboard.general.string = address
            withAnimation {
                isCopied = true
            }
            
            // Show a temporary alert
            showCopiedAlert = true
            
            // Reset copied indicator after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCopied = false
                }
            }
        }
        .alert("Address Copied", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The address has been copied to your clipboard.")
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
