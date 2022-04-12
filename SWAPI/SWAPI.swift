//
//  SWAPI.swift
//  SWAPI
//
//  Created by Александр Фомин on 10.04.2022.
//

import Foundation

protocol WebService {
    func getPeople(completion: @escaping ([PeopleViewModel], URL?) -> ())
    func getPeople(page: URL?, completion: @escaping ([PeopleViewModel], URL?) -> ())
}

enum APIError: Error {
    case unexpectedResponse
    case cantCreateBaseUrl
    case cantCreateRelativeUrl
    case cantCreateNextPageUrl
    case cantCreateNextPage
}

enum ModelType: String {
    case people = "people/"
    case films = "films/"
    case planets = "planets/"
    case species = "species/"
    case starships = "starships/"
    case vehicles = "vehicles/"
}

class SWAPIService: WebService {
    
    private func baseUrl() throws -> URL {
        guard let url = URL(string: "https://swapi.dev") else {
            throw APIError.cantCreateBaseUrl
        }
        return url
    }
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private func requestData(from url: URL, completion: @escaping (Result<Data, Error>) -> ()) {
        session.dataTask(with: url) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError.unexpectedResponse))
                return
            }
            
            guard 200 ..< 300 ~= httpResponse.statusCode else {
                let error = NSError(domain: "HttpResponseError",
                                    code: httpResponse.statusCode,
                                    userInfo: [NSLocalizedDescriptionKey: "Status code was \(httpResponse.statusCode), but expected 2xx"])
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else if let error = error {
                completion(.failure(error))
            }
            
            debugPrint("Load \(url.absoluteString)")
        }.resume()
    }
    
    func getPeople(completion: @escaping ([PeopleViewModel], URL?) -> ()) {
        do {
            let firstPageURL = try makeURL(model: .people)
            getPeople(page: firstPageURL, completion: completion)
        } catch {
            debugPrint(error)
        }
    }
    
    func getPeople(page: URL?, completion: @escaping ([PeopleViewModel], URL?) -> ()) {
        guard let url = page else { return }
        
        requestData(from: url) { result in
            switch result {
            case .success(let data):
                do {
                    let peopleGroup = DispatchGroup()
                    let currentPage = try JSONDecoder().decode(PeoplePage.self, from: data)
                    var peopleViewModel = [PeopleViewModel]()
                    
                    currentPage.people.forEach { creature in
                        let detailGroup = DispatchGroup()
                        let planetURL = URL(string: creature.homeWorldUrl)
                        var viewModel = PeopleViewModel(name: creature.name,
                                                        species: "Human",
                                                        homeworld: "none")
                        peopleGroup.enter()
                        detailGroup.enter()
                        self.getPlanet(url: planetURL) { planet in
                            viewModel.homeworld = planet.name
                            detailGroup.leave()
                        }
                        
                        if let URLString = creature.spacesUrl.first,
                           let speciesURL = URL(string: URLString) {
                            detailGroup.enter()
                            self.getSpecies(url: speciesURL) { (species) in
                                viewModel.species = species.name
                                detailGroup.leave()
                            }
                        }
                        
                        detailGroup.notify(queue: .global()) {
                            peopleViewModel.append(viewModel)
                            peopleGroup.leave()
                        }
                    }
                    
                    peopleGroup.notify(queue: .main) {
                        completion(peopleViewModel, currentPage.next)
                    }
             
                } catch {
                    debugPrint(error)
                }
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
    
    private func getPlanet(url: URL?, completion: @escaping (Planet) -> ()) {
        guard let url = url else { return }
        
        requestData(from: url) { result in
            switch result {
            case .success(let data):
                do {
                    let planet = try JSONDecoder().decode(Planet.self, from: data)
                    completion(planet)
                } catch {
                    debugPrint(error)
                }
            case .failure(let error):
                debugPrint(error)
            }
        }
    }
    
    private func getSpecies(url: URL?, completion: @escaping (Species) -> ()) {
        guard let url = url else { return }
        
        requestData(from: url) { result in
            switch result {
            case .success(let data):
                do {
                    let species = try JSONDecoder().decode(Species.self, from: data)
                    completion(species)
                } catch {
                    debugPrint(error)
                }
            case .failure(let error):
                debugPrint(error)
            }
        }
    }

    private func makeURL(model: ModelType) throws -> URL {
        guard var components = URLComponents(url: try self.baseUrl(), resolvingAgainstBaseURL: true) else {
            throw APIError.cantCreateNextPageUrl
        }
        
        var queryItems = [URLQueryItem]()
        let queryItem = URLQueryItem(name: "page", value: "\(1)")
        queryItems.append(queryItem)
        
        components.path = "/api/" + model.rawValue
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.cantCreateNextPage
        }
        return url
    }
}
