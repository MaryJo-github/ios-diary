//
//  WeatherManager.swift
//  Diary
//
//  Created by MARY on 2024/02/02.
//

import Moya
import Foundation
import CoreLocation

final class WeatherManager {
    let provider: MoyaProvider<WeatherTargetType>
    
    init(provider: MoyaProvider<WeatherTargetType> = .init()) {
        self.provider = provider
    }
    
    func fetchWeatherImageURL(id: String) -> URL? {
        let url = "https://openweathermap.org/img/wn/\(id)@2x.png"
        return URL(string: url)
    }
    
    func fetchWeather(lat: Double, lon: Double) async throws -> OpenWeather {
        return try await withCheckedThrowingContinuation { continuation in
            fetchWeather(lat: lat, lon: lon) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func fetchWeather(lat: Double, lon: Double, completion: @escaping (Result<OpenWeather, Error>) -> Void) {
        provider.request(.fetchWeather(lat: lat, lon: lon)) { result in
            switch result {
            case .success(let response):
                do {
                    let decodedData = try JSONDecoder().decode(OpenWeather.self, from: response.data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
