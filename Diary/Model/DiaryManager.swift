//
//  DiaryManager.swift
//  Diary
//
//  Created by Mary & Whales on 2023/08/30.
//

import OSLog

final class DiaryManager {
    var diaryContents: [DiaryContent]?
    
    func fetchDiaryContents() throws {
        guard let data: [Diary] = ContainerManager.shared.fetchAll() else { return }
        
        var contents: [DiaryContent] = []
        
        data.forEach { element in
            contents.append(DiaryContent(id: element.id,
                                         title: element.title,
                                         body: element.body,
                                         timeInterval: element.timeInterval))
        }
        
        diaryContents = contents
    }
}
