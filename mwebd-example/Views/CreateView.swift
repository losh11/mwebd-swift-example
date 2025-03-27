import SwiftUI
import Mwebd
import BitcoinKit

struct CreateView: View {
    @State private var mnemonicWords: [String] = Array(repeating: "", count: 12)
    @State private var isWalletCreated = false
    @State private var isRecovering = false
    
    var onWalletCreated: (([String]) -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isRecovering ? "Recover Wallet" : "Create a New Wallet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            if isWalletCreated {
                Text("Your recovery phrase")
                    .font(.headline)
                    .padding(.top, 10)
                
                Text("Write down these 12 words in order and keep them in a safe place.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(0..<mnemonicWords.count, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            Text(mnemonicWords[index])
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Button(action: {
                    onWalletCreated?(mnemonicWords)
                }) {
                    Text("Continue to Wallet")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            } else if isRecovering {
                Text("Enter your 12-word recovery phrase")
                    .font(.headline)
                    .padding(.top, 10)
                
                Text("Enter all words in the correct order")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(0..<mnemonicWords.count, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            TextField("Word \(index + 1)", text: $mnemonicWords[index])
                                .padding(5)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                VStack(spacing: 12) {
                    HStack {
                        Button(action: {
                            isRecovering = false
                            mnemonicWords = Array(repeating: "", count: 12)
                        }) {
                            Text("Cancel")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            isWalletCreated = true
                        }) {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        mnemonicWords = ["enough", "please", "spice", "outdoor", "cousin", "entire", "quantum", "wheel", "lottery", "range", "onion", "clutch"]
                    }) {
                        Text("Skip (Demo)")
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            } else {
                Spacer()
                
                Image(systemName: "bitcoinsign.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Create a new Litecoin wallet")
                    .font(.headline)
                    .padding()
                
                Text("This will generate a unique 12-word recovery phrase.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        generateMnemonic()
                    }) {
                        Text("Create Wallet")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isRecovering = true
                    }) {
                        Text("Recover Wallet")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
    
    private func generateMnemonic() {
        do {
            let mnemonic = try Mnemonic.generate()
            self.mnemonicWords = mnemonic
            isWalletCreated = true
        } catch {
            print("Error generating mnemonic: \(error)")
        }
    }
}

struct CreateView_Previews: PreviewProvider {
    static var previews: some View {
        CreateView()
    }
}
