//
//  DetailFlow.swift
//  Presentation
//

import Combine

public enum DetailFlow {
    case pushEdit(EditSceneInput)
    case pushImagePicker(ImagePickerSceneInput)
}

public protocol DetailFlowEmitting: AnyObject {
    var flowPublisher: AnyPublisher<DetailFlow, Never> { get }
}
