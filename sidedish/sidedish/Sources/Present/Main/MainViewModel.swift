//
//  MainViewModel.swift
//  sidedish
//
//  Created by Jihee hwang on 2022/04/19.
//

import Combine
import Foundation

struct MainViewModelAction {
    let loadData = PassthroughSubject<[Sidedish.Menu], Never>()
}

struct MainViewModelState {
    let loadedData = PassthroughSubject<Sidedish.Menu, Never>()
}

protocol MainViewModelBinding {
    var action: MainViewModelAction { get }
    var state: MainViewModelState { get }
}

protocol MainViewModelProperty {
    subscript(_ indexPath: IndexPath) -> Sidedish? { get }
}

typealias MainViewModelProtocol = MainViewModelBinding & MainViewModelProperty

class MainViewModel: MainViewModelBinding, MainViewModelProperty {
    let action = MainViewModelAction()
    let state = MainViewModelState()
    
    subscript(_ indexPath: IndexPath) -> Sidedish? {
        guard let type = Sidedish.Menu(rawValue: indexPath.section),
              let menus = self.menus[type] else {
            return nil
        }
        
        return menus[indexPath.item]
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private let sidedishRepository: SidedishRepository = SidedishRepositoryImpl()
    private var menus = [Sidedish.Menu: [Sidedish]]()
    
    init() {
        let request = action.loadData
            .map { $0.publisher }
            .map { result in
                result.map { self.sidedishRepository.loadMenu($0) }
            }
            .switchToLatest()
            .share()
        
        request
            .sink { result in
                result
                    .compactMap { $0.value }
                    .sink { type, menus in
                        self.menus[type] = menus
                        self.state.loadedData.send(type)
                    }.store(in: &self.cancellables)
                
                result
                    .compactMap { $0.error }
                    .sink { error in
                        print(error)
                    }.store(in: &self.cancellables)
            }.store(in: &cancellables)
    }
}
