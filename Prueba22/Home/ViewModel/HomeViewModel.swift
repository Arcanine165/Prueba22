//
//  HomeViewModel.swift
//  Prueba22
//
//  Created by Victor Alejandro Perez Valdez on 04/11/26.
//

import Foundation
import Combine

protocol IHomeViewModel {
    var jokes: [JokeModel] { get }
    var jokePublisher: AnyPublisher<[JokeModel],Never> { get }
    func fetchJoke() async
}


@MainActor
final class HomeViewModel: IHomeViewModel {
    @Published private(set) var jokes: [JokeModel] = []
    @Published private(set) var localError: String?
    
    var jokePublisher: AnyPublisher<[JokeModel], Never> {
        $jokes.eraseToAnyPublisher()
    }
    
    private let service: HomeService

    init(service: HomeService? = nil) {
        self.service = service ?? HomeService()
    }
    
    func fetchJoke() async {
        guard jokes.count < 10 else { return }
        do {
            var joke = try await service.getRandomJoke()
            var intentos = 0
            while jokes[joke.id] != nil && intentos < 5 {
                joke = try await service.getRandomJoke()
                intentos += 1
            }
            jokes.append(joke)
        } catch(let error) {
            localError = error.localizedDescription
        }
        
    }
}

final class HomeService {
    let networkLayer: INetworkLayer
    init(networkLayer: INetworkLayer? = nil) {
        self.networkLayer = networkLayer ?? NetworkLayer()
    }
    
    func getRandomJoke() async throws -> JokeModel {
        try await networkLayer.fetch(path: .random)
    }
}
