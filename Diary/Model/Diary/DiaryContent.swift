//
//  DiaryContent.swift
//  Diary
//
//  Created by Mary & Whales on 8/30/23.
//

import Foundation

struct DiaryContent {
    let id: UUID
    var title: String
    var body: String
    let timeInterval: Double
    var weatherTitle: String?
    var weatherId: String?
    var date: String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formattedDate = DateFormatter().format(from: date, dateStyle: .long, timeStyle: .none)
        
        return formattedDate
    }
    
    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        timeInterval: Double = Date().timeIntervalSince1970,
        weatherTitle: String? = nil,
        weatherId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.timeInterval = timeInterval
        self.weatherTitle = weatherTitle
        self.weatherId = weatherId
    }
}
