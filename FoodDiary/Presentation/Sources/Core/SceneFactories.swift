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
    public let detail: any DetailSceneProducing
    public let imagePicker: any ImagePickerSceneProducing
    public let edit: any EditSceneProducing
    public let addressSearch: any AddressSearchSceneProducing

    public init(
        login: any LoginSceneProducing,
        calendar: any CalendarSceneProducing,
        insight: any InsightSceneProducing,
        myPage: any MyPageSceneProducing,
        detail: any DetailSceneProducing,
        imagePicker: any ImagePickerSceneProducing,
        edit: any EditSceneProducing,
        addressSearch: any AddressSearchSceneProducing
    ) {
        self.login = login
        self.calendar = calendar
        self.insight = insight
        self.myPage = myPage
        self.detail = detail
        self.imagePicker = imagePicker
        self.edit = edit
        self.addressSearch = addressSearch
    }
}
