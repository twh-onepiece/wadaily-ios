import SwiftUI
import PhotosUI

enum RegistrationStep {
    case emailPassword
    case userId
    case images
    case profile
}

struct RegistrationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep: RegistrationStep = .emailPassword
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userId = ""
    @State private var iconImage: UIImage?
    @State private var backgroundImage: UIImage?
    @State private var profileText = ""
    
    @State private var showIconPicker = false
    @State private var showBackgroundPicker = false
    @State private var selectedIconItem: PhotosPickerItem?
    @State private var selectedBackgroundItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 20) {
                    ProgressView(value: progressValue, total: 4.0)
                        .padding()
                    
                    switch currentStep {
                    case .emailPassword:
                        emailPasswordStep
                    case .userId:
                        userIdStep
                    case .images:
                        imagesStep
                    case .profile:
                        profileStep
                    }
                    
                    Spacer()
                    
                    HStack {
                        if currentStep != .emailPassword {
                            Button("戻る") {
                                previousStep()
                            }
                            .padding()
                        }
                        
                        Spacer()
                        
                        Button(currentStep == .profile ? "登録" : "次へ") {
                            handleNextButton()
                        }
                        .disabled(!canProceed)
                        .padding()
                    }
                }
                .navigationTitle("新規登録")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var emailPasswordStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            Spacer()
            
            Text("メールアドレスとパスワードを入力")
                .font(.headline)
            
            TextField("メールアドレス", text: $email)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("パスワード", text: $password)
                .textFieldStyle(RoundedTextFieldStyle())
            
            SecureField("パスワード(確認)", text: $confirmPassword)
                .textFieldStyle(RoundedTextFieldStyle())
            
            if !password.isEmpty && password != confirmPassword {
                Text("パスワードが一致しません")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()

        }
        .padding()
    }
    
    private var userIdStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("ユーザーIDを入力")
                .font(.headline)
            
            TextField("ユーザーID", text: $userId)
                .textFieldStyle(RoundedTextFieldStyle())
                .autocapitalization(.none)
            
            Text("このIDでログインします")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var imagesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("画像を設定")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("アイコン画像")
                    .font(.subheadline)
                
                if let iconImage {
                    Image(uiImage: iconImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                
                PhotosPicker(selection: $selectedIconItem, matching: .images) {
                    Text(iconImage == nil ? "アイコンを選択" : "アイコンを変更")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .onChange(of: selectedIconItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            iconImage = image
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("背景画像")
                    .font(.subheadline)
                
                if let backgroundImage {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(8)
                }
                
                PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                    Text(backgroundImage == nil ? "背景画像を選択" : "背景画像を変更")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .onChange(of: selectedBackgroundItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            backgroundImage = image
                        }
                    }
                }
            }
            
            Text("画像は任意です。スキップできます")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("プロフィール文を入力")
                .font(.headline)
            
            TextEditor(text: $profileText)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            
            Text("プロフィールは任意です。スキップできます")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .emailPassword: return 1.0
        case .userId: return 2.0
        case .images: return 3.0
        case .profile: return 4.0
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .emailPassword:
            return !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        case .userId:
            return !userId.isEmpty
        case .images:
            return true // 画像は任意
        case .profile:
            return true // プロフィールは任意
        }
    }
    
    private func handleNextButton() {
        switch currentStep {
        case .emailPassword:
            currentStep = .userId
        case .userId:
            currentStep = .images
        case .images:
            currentStep = .profile
        case .profile:
            registerUser()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .emailPassword:
            break
        case .userId:
            currentStep = .emailPassword
        case .images:
            currentStep = .userId
        case .profile:
            currentStep = .images
        }
    }
    
    private func registerUser() {
        Task {
            await viewModel.register(
                email: email,
                password: password,
                userId: userId,
                iconImageData: iconImage?.jpegData(compressionQuality: 0.7),
                backgroundImageData: backgroundImage?.jpegData(compressionQuality: 0.7),
                profileText: profileText.isEmpty ? nil : profileText
            )
            
            if case .authenticated = viewModel.authState {
                dismiss()
            }
        }
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
    
    return RegistrationView(viewModel: viewModel)
}
