import Foundation
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCProtobuf
import ArgumentParser

class MwebClient {
    private let host: String
    private let port: Int
    private let useTLS: Bool
    
    init(host: String, port: Int, useTLS: Bool = false) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
    }
    
    /// Get the sync status of the MWEBD daemon
    /// - Returns: StatusResponse with current sync status
    func getStatus() async throws -> StatusResponse {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            let rpcClient = Rpc.Client(wrapping: client)
            let request = StatusRequest()
            return try await rpcClient.status(request)
        }
    }
    
    /// Get unspent MWEB outputs (UTXOs) for an account
    /// - Parameters:
    ///   - fromHeight: Block height from which to start fetching UTXOs
    ///   - scanSecret: Scan secret or view key for the account
    /// - Returns: Array of UTXOs
    func getUtxos(fromHeight: Int32, scanSecret: Data) async throws -> [Utxo] {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            _ = Rpc.Client(wrapping: client)
            var request = UtxosRequest()
            request.fromHeight = fromHeight
            request.scanSecret = scanSecret
            
            return try await client.serverStreaming(
                request: ClientRequest(message: request),
                descriptor: Rpc.Method.Utxos.descriptor,
                serializer: GRPCProtobuf.ProtobufSerializer<UtxosRequest>(),
                deserializer: GRPCProtobuf.ProtobufDeserializer<Utxo>(),
                options: .defaults
            ) { response in
                var utxoCollection = [Utxo]()
                for try await utxo in response.messages {
                    utxoCollection.append(utxo)
                }
                return utxoCollection
            }
        }
    }

    /// Get a batch of MWEB addresses for an account
    /// - Parameters:
    ///   - fromIndex: Starting index
    ///   - toIndex: Ending index (exclusive)
    ///   - scanSecret: Scan secret or view key for the account
    ///   - spendPubkey: Public key of the spend secret
    /// - Returns: AddressResponse containing the addresses
    func getAddresses(fromIndex: UInt32, toIndex: UInt32, scanSecret: Data, spendPubkey: Data) async throws -> AddressResponse {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            let rpcClient = Rpc.Client(wrapping: client)
            var request = AddressRequest()
            request.fromIndex = fromIndex
            request.toIndex = toIndex
            request.scanSecret = scanSecret
            request.spendPubkey = spendPubkey
            
            return try await rpcClient.addresses(request)
        }
    }
    
    /// Check whether MWEB outputs are in the unspent set
    /// - Parameter outputIDs: Array of output IDs to check
    /// - Returns: SpentResponse with the outputs that are spent
    func checkSpent(outputIDs: [String]) async throws -> SpentResponse {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            let rpcClient = Rpc.Client(wrapping: client)
            var request = SpentRequest()
            request.outputID = outputIDs
            
            return try await rpcClient.spent(request)
        }
    }
    
    /// Create the MWEB portion of a transaction
    /// - Parameters:
    ///   - rawTx: Raw transaction bytes
    ///   - scanSecret: Scan secret or view key for the account
    ///   - spendSecret: Spend secret for the account
    ///   - feeRatePerKb: Fee rate per KB in litoshis
    ///   - dryRun: Whether to skip MWEB transaction creation (for fee estimation)
    /// - Returns: CreateResponse with the transaction and output IDs
    func createTransaction(rawTx: Data, scanSecret: Data, spendSecret: Data, feeRatePerKb: UInt64, dryRun: Bool = false) async throws -> CreateResponse {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            let rpcClient = Rpc.Client(wrapping: client)
            var request = CreateRequest()
            request.rawTx = rawTx
            request.scanSecret = scanSecret
            request.spendSecret = spendSecret
            request.feeRatePerKb = feeRatePerKb
            request.dryRun = dryRun
            
            return try await rpcClient.create(request)
        }
    }
    
    /// Broadcast a transaction to the network
    /// - Parameter rawTx: Raw transaction bytes
    /// - Returns: BroadcastResponse with the transaction ID
    func broadcastTransaction(rawTx: Data) async throws -> BroadcastResponse {
        let transportSecurity: GRPCNIOTransportCore.HTTP2ClientTransport.Posix.TransportSecurity = useTLS ? .tls : .plaintext
        
        return try await withGRPCClient(
            transport: .http2NIOPosix(
                target: .ipv4(host: host, port: port),
                transportSecurity: transportSecurity
            )
        ) { client in
            let rpcClient = Rpc.Client(wrapping: client)
            var request = BroadcastRequest()
            request.rawTx = rawTx
            
            return try await rpcClient.broadcast(request)
        }
    }
}
