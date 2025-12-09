import SwiftUI

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(16)
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var userId = ""
    @State private var password = ""
    @State private var showRegistration = false
    @State private var showDummyAccountSelect = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 20) {
                    Spacer()
                
                Text("Wadaily")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("話題を考えない通話アプリ")
                    .font(.subheadline)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Login")
                        .font(.headline)
                    
                    TextField("ユーザーID", text: $userId)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .autocapitalization(.none)
                    
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                
                Button(action: {
                    Task {
                        await viewModel.login(userId: userId, password: password)
                    }
                }) {
                    Text("ログイン")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canLogin ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(!canLogin)
                .padding(.horizontal)
                
                Button("新規登録") {
                    showRegistration = true
                }
                .padding()
                
                Button("ダミーアカウントでログイン") {
                    showDummyAccountSelect = true
                }
                .padding(.bottom)
                
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showRegistration) {
                RegistrationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showDummyAccountSelect) {
                DummyAccountSelectView(viewModel: viewModel)
            }
        }
    }
    
    private var canLogin: Bool {
        !userId.isEmpty && !password.isEmpty
    }
}

#Preview {
    let mockAuthRepo = MockAuthRepository()
    let viewModel = AuthViewModel(authRepository: mockAuthRepo)
    
    LoginView(viewModel: viewModel)
}
