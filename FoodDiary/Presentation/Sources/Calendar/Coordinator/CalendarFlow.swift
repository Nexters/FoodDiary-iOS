//
//  CalendarFlow.swift
//  Presentation
//

import Combine

public enum CalendarFlow {
    case pushDetail(DetailSceneInput)
    case pushImagePicker(ImagePickerSceneInput)
}

public protocol CalendarFlowEmitting: AnyObject {
    var flowPublisher: AnyPublisher<CalendarFlow, Never> { get }
}
