//
//  SceneProducing.swift
//  Presentation
//

import UIKit

public struct Factories {
    public let login: any LoginSceneProducing
    public let calendar: any CalendarSceneProducing
    public let insight: any InsightSceneProducing
    public let myPage: any MyPageSceneProducing

    public init(
        login: any LoginSceneProducing,
        calendar: any CalendarSceneProducing,
        insight: any InsightSceneProducing,
        myPage: any MyPageSceneProducing
    ) {
        self.login = login
        self.calendar = calendar
        self.insight = insight
        self.myPage = myPage
    }
}
