//
//  SceneProducing.swift
//  Presentation
//

import UIKit

public struct Factories {
    public let login: LoginSceneFactory
    public let calendar: CalendarSceneFactory
    public let insight: InsightSceneFactory
    public let myPage: MyPageSceneFactory
    public let detail: DetailSceneFactory
    public let imagePicker: ImagePickerSceneFactory
    public let edit: EditSceneFactory
    public let addressSearch: AddressSearchSceneFactory

    public init(
        login: LoginSceneFactory,
        calendar: CalendarSceneFactory,
        insight: InsightSceneFactory,
        myPage: MyPageSceneFactory,
        detail: DetailSceneFactory,
        imagePicker: ImagePickerSceneFactory,
        edit: EditSceneFactory,
        addressSearch: AddressSearchSceneFactory
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
