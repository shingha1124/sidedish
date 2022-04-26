//
//  LoginViewModel.swift
//  sidedish
//
//  Created by seongha shin on 2022/04/25.
//

import Combine
import FirebaseAuth
import Foundation

struct LoginViewModelAction {
    let viewDidLoad = PassthroughSubject<Void, Never>()
    let tappedGoogleLogin = PassthroughSubject<Void, Never>()
}

struct LoginViewModelState {
    let presentMainView = PassthroughSubject<Void, Never>()
}

protocol LoginViewModelBinding {
    var action: LoginViewModelAction { get }
    var state: LoginViewModelState { get }
}

protocol LoginViewDelegate: AnyObject {
    func getViewController() -> UIViewController
}

protocol LoginViewModelProperty {
    var delegate: LoginViewDelegate? { get set }
}

typealias LoginViewModelProtocol = LoginViewModelBinding & LoginViewModelProperty

class LoginViewModel: LoginViewModelProtocol {
    
    private var cancellables = Set<AnyCancellable>()
    private let loginRepository: LoginRepository = LoginRepositoryImpl()
    
    let action = LoginViewModelAction()
    let state = LoginViewModelState()
    weak var delegate: LoginViewDelegate?
    
    init() {
        action.viewDidLoad
            .compactMap { self.loginRepository.getUser() }
            .switchToLatest()
            .handleEvents(receiveOutput: { Container.shared.userStore.user = $0 })
            .sink { _ in
                self.state.presentMainView.send()
            }
            .store(in: &cancellables)
                    
        action.tappedGoogleLogin
            .compactMap { self.delegate?.getViewController() }
            .map { self.loginRepository.googleLogin(viewController: $0) }
            .switchToLatest()
            .handleEvents(receiveOutput: { Container.shared.userStore.user = $0 })
            .map { _ in }
            .sink(receiveValue: state.presentMainView.send(_:))
            .store(in: &cancellables)
    }
}
