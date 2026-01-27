//
//  DIContainer.swift
//  DI
//
//  Created by 강대훈 on 1/23/26.
//

import Swinject

public final class DIContainer {
    public static let shared = DIContainer()
    
    private let container: Container
    
    private init() {
        container = Container()
    }
    
    public func register<Service>(
        _ serviceType: Service.Type,
        scope: ObjectScope = .container,
        factory: @escaping (Resolver) -> Service
    ) {
        container.register(serviceType, factory: factory)
            .inObjectScope(scope)
    }
    
    public func resolve<Service>(_ serviceType: Service.Type) throws -> Service {
        guard let service = container.resolve(serviceType) else {
            throw DIContainerError.resolveFailure(service: String(describing: serviceType))
        }
        
        return service
    }
}


