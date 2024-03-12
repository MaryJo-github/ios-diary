//
//  WeatherTargetType.swift
//  Diary
//
//  Created by MARY on 2024/02/02.
//

import Foundation
import Moya

enum WeatherTargetType {
    case fetchWeather(lat: Double, lon: Double)
}

extension WeatherTargetType: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.openweathermap.org")!
    }
    
    var path: String {
        switch self {
        case .fetchWeather:
            return "data/2.5/weather"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Moya.Task {
        switch self {
        case .fetchWeather(let lat, let lon):
            if let apiKey = Bundle.main.infoDictionary?["OpenWeatherKey"] as? String {
                return .requestParameters(
                    parameters: ["lat": lat, "lon": lon, "appid": apiKey],
                    encoding: URLEncoding.queryString
                )
            }
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        return nil
    }
}
