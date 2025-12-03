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
                
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showRegistration) {
                RegistrationView(viewModel: viewModel)
            }
        }
    }
    
    private var canLogin: Bool {
        !userId.isEmpty && !password.isEmpty
    }
}

#Preview {
    class MockAuthRepository: AuthRepositoryProtocol {
        func register(email: String, password: String, userId: String, iconImageData: Data?, backgroundImageData: Data?, profileText: String?) async throws -> User {
            return User(id: "1", email: email, userId: userId, iconImageData: iconImageData, backgroundImageData: backgroundImageData, profileText: profileText)
        }
        
        func login(userId: String, password: String) async throws -> User {
            return User(id: "1", email: "test@example.com", userId: userId)
        }
        
        func logout() async throws {}
        
        func getCurrentUser() async throws -> User? {
            return nil
        }
    }
    
    let mockAuthRepo = MockAuthRepository()
    let mockStorage = UserDefaultsStorage()
    let viewModel = AuthViewModel(authRepository: mockAuthRepo, localStorage: mockStorage)
    
    return LoginView(viewModel: viewModel)
}
