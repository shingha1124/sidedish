//
//  SidedishDetailViewController.swift
//  sidedish
//
//  Created by seongha shin on 2022/04/18.
//

import Combine
import UIKit

class MenuDetailViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    private let model: MenuDetailViewModelProtcol

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isPagingEnabled = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let thumbnailImageView: ThumbnailImageView = {
        let thumbnailView = ThumbnailImageView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = .red
        return thumbnailView
    }()
    
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        return stackView
    }()
    
    private let infoView: MenuInfoView = {
        let attribute = MenuInfoAttribute(stackViewSpacing: 8,
                                          titleFont: .systemFont(ofSize: 32, weight: .regular), titleTextColor: .black,
                                          discriptionFont: .systemFont(ofSize: 14, weight: .regular), discriptionTextColor: .grey2,
                                          priceFont: .systemFont(ofSize: 18, weight: .bold), priceTextColor: .grey1,
                                          salePriceFont: .systemFont(ofSize: 16), salePriceTextColor: .grey2,
                                          badgeStackViewSpacing: 4)
        let view = MenuInfoView(attribute: attribute)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let subInfoView = MenuSubInfoView()
    
    private let amountView = MenuAmountView()
    
    private let orderView = MenuOrderView()

    private let separator = (0..<3).map { _ -> UIView in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .grey3
        return view
    }
    
    init(model: MenuDetailViewModelProtcol) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        attribute()
        layout()

        model.action.loadMenuDetail.send()
    }

    private func bind() {
        model.state.loadedDetail
            .receive(on: DispatchQueue.main)
            .sink { menu, detail in
                self.title = detail.description
                self.infoView.changeTitleLabel(text: menu.title)
                self.infoView.changeDescriptionLabel(text: menu.description)
                self.infoView.changePriceLabel(text: menu.price)
                self.infoView.changeSalePriceLabel(text: menu.salePrice ?? "")
                self.infoView.changeSaleBadge(menu.badge)
                self.subInfoView.setData(detail)
                self.orderView.setTotalPrice(menu.price)
            }.store(in: &cancellables)

        model.state.showError
            .sink { _ in
                //TODO: 에러 처리
            }.store(in: &cancellables)

        amountView.plusPublisher
            .sink(receiveValue: model.action.tappedPlusButton.send(_:))
            .store(in: &cancellables)

        amountView.minusPublisher
            .sink(receiveValue: model.action.tappedMinusButton.send(_:))
            .store(in: &cancellables)

        model.state.amount
            .sink {
                self.amountView.amount = $0
            }
            .store(in: &cancellables)

        orderView.orderPublisher
            .sink(receiveValue: model.action.tappedOrderButton.send(_:))
            .store(in: &cancellables)

        model.state.ordered
            .sink {
                // TODO: 주문완료 처리
            }.store(in: &cancellables)
    }

    private func attribute() {
        view.backgroundColor = .white
    }

    private func layout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(infoStackView)

        let infoViews = [infoView, separator[0], subInfoView, separator[1], amountView, separator[2], orderView]
        infoViews.forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        separator.forEach {
            $0.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            scrollView.contentLayoutGuide.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.contentLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: safeArea.topAnchor),

            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),

            thumbnailImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            thumbnailImageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.widthAnchor),

            infoStackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16),
            infoStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16),
            infoStackView.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 24),
            infoStackView.bottomAnchor.constraint(equalTo: infoViews[infoViews.count - 1].bottomAnchor),

            contentView.bottomAnchor.constraint(equalTo: infoStackView.bottomAnchor),
            scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }
}
