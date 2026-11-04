//
//  ViewController.swift
//  Prueba22
//
//  Created by Victor Alejandro Perez Valdez on 04/11/26.
//

import UIKit
import Combine

class ViewController: UIViewController {
    private let homeViewModel: IHomeViewModel = HomeViewModel()
    private var fetchRequest: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    
    private var lastYPosition: CGFloat = 0
    private var tolerance: CGFloat = 80
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(JokeViewCell.self, forCellWithReuseIdentifier: JokeViewCell.description())
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCollectionView()
        setupObservers()
        fetchRequest = Task {
            await homeViewModel.fetchJoke()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchRequest?.cancel()
        fetchRequest = nil
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.register(JokeViewCell.self, forCellWithReuseIdentifier: JokeViewCell.identifier)
    }
    
    private func setupView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        )
    }
    
    private func setupObservers() {
        homeViewModel
            .jokePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] joke in
                print(joke)
                guard let self else { return }
                self.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        homeViewModel.jokes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JokeViewCell.identifier, for: indexPath) as? JokeViewCell else {
            assertionFailure("JOKE CEll No Registered")
            return UICollectionViewCell()
        }
        
        cell.configure(with: homeViewModel.jokes[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.window?.bounds.size.width ?? 0, height: 150)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let postionY = scrollView.contentOffset.y
        
        guard postionY > 0 else { return }
        
        let difference = postionY - lastYPosition
        
        if abs(difference) > tolerance {
            if difference > 0 {
                Task {
                    await homeViewModel.fetchJoke()
                }
            } else {
                Task {
                    await homeViewModel.fetchJoke()
                }            }
            self.lastYPosition = postionY
        }
    }
    
}

final class JokeViewCell: UICollectionViewCell {
    static let identifier: String = "JokeViewCell"
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with joke: JokeModel) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            imageView.image = await ImageLoader.shared.loadImage(from: URL(string: joke.iconURL))
        }
        descriptionLabel.text = joke.description
    }
    
    private func setupView() {
        contentView.addSubview(imageView)
        contentView.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 50),
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    
}

final class ImageLoader {
    static let shared: ImageLoader = .init()
    private let cache: NSCache<NSString, UIImage> = .init()
    private init() {}
    
    func loadImage(from url: URL?) async -> UIImage? {
        guard let url else {
            return nil
        }
        if let image: UIImage = cache.object(forKey: url.absoluteString as NSString) {
            return image
        } else {
            if Task.isCancelled { return nil }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if Task.isCancelled { return nil }
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    return nil
                }
                let imageDecoded: UIImage? = UIImage(data: data)
                if let imageDecoded {
                    cache.setObject(imageDecoded, forKey: url.absoluteString as NSString)
                    return imageDecoded
                } else {
                    return nil
                }
            } catch let error as URLError where error.code == .cancelled {
                return nil
            } catch {
                return nil
            }
            
        }
    }
}
