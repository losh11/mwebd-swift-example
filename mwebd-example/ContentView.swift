import SwiftUI
import Mwebd

struct ContentView: View {
    @State private var isRunning = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Button(action: startMwebd) {
                Text(isRunning ? "Mwebd Running" : "Start Mwebd")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    func startMwebd() {
        stopServer()
        
        let args = MwebdServerArgs()
        args.chain = "mainnet"
        args.dataDir = "/path/to/datadirectory"
        args.peerAddr = "88.198.50.4:9333"
        args.proxyAddr = ""
        
        var error: NSError?
        guard let server = MwebdNewServer2(args, &error) else {
            errorMessage = error?.localizedDescription ?? "Unknown error"
            return
        }
        
        var port: Int = 0
    
        do {
            _ = try server.start(9332, ret0_: &port)
            isRunning = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopServer() {
        if isRunning == true {
            stopServer()
            isRunning = false
        }
    }
}

#Preview {
    ContentView()
}
