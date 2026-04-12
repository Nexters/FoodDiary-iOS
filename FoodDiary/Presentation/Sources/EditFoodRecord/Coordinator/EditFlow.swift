//
//  EditFlow.swift
//  Presentation
//

import Combine

public enum EditFlow {
    case presentAddressSearch(AddressSearchSceneInput)
}

public protocol EditFlowEmitting: AnyObject {
    var flowPublisher: AnyPublisher<EditFlow, Never> { get }
}
