//
//  OpenWeather.swift
//  Diary
//
//  Created by MARY on 2024/02/02.
//

struct OpenWeather: Decodable {
    let weather: [Info]
    
    struct Info: Decodable {
        let main: String
        let icon: String
    }
}
