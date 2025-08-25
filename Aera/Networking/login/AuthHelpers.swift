//
//  AuthHelpers.swift
//  Aera
//
//  Created by Dream 話 on 2025/8/23.
//

import SwiftUI
// AuthHelpers.swift
import SwiftUI
import AuthenticationServices
import GoogleSignIn

// MARK: - Google
struct GoogleSignInButtonView: View {
    let clientID: String? // 可不传，若已在 Info.plist 写了 GIDClientID
    let onResult: (Result<String, Error>) -> Void  // 返回 idToken

    var body: some View {
        Button {
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController else { return }

//            let config = GIDConfiguration(clientID: clientID ?? GIDSignIn.sharedInstance.clientID)
            var config = GIDConfiguration(clientID: clientID ?? "203852779171-8esqsrqpotkn5sr3neidqj2gf6kt2tou.apps.googleusercontent.com")
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let clientID = dict["CLIENT_ID"] as? String {
                config = GIDConfiguration(clientID: clientID)
            }
            
            GIDSignIn.sharedInstance.configuration = config

            GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
                if let error = error { onResult(.failure(error)); return }
                guard let token = result?.user.idToken?.tokenString else {
                    onResult(.failure(NSError(domain: "Google", code: -1, userInfo: [NSLocalizedDescriptionKey: "缺少 idToken"])))
                    return
                }
                onResult(.success(token))
            }
        } label: {
            HStack {
                Image(systemName: "g.circle.fill")
                Text("使用 Google 登录")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

// MARK: - Apple
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let onResult: (Result<String, Error>) -> Void
    init(onResult: @escaping (Result<String, Error>) -> Void) { self.onResult = onResult }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            onResult(.failure(NSError(domain: "Apple", code: -1, userInfo: [NSLocalizedDescriptionKey: "缺少 identityToken"])))
            return
        }
        onResult(.success(token))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onResult(.failure(error))
    }
}

struct AppleSignInButtonView: View {
    let onResult: (Result<String, Error>) -> Void  // 返回 identityToken
    @State private var coordinator: AppleSignInCoordinator? = nil

    var body: some View {
        SignInWithAppleButton(.signIn) { _ in
            let coord = AppleSignInCoordinator(onResult: onResult)
            coordinator = coord
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let ctrl = ASAuthorizationController(authorizationRequests: [request])
            ctrl.delegate = coord
            ctrl.presentationContextProvider = coord
            ctrl.performRequests()
        } onCompletion: { _ in }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 44)
    }
}
