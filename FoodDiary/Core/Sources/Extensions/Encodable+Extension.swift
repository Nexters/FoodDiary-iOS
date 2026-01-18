//
//  Encodable+Extension.swift
//  Core
//
//  Created by 강대훈 on 1/18/26.
//

import Foundation

extension Encodable {
    public func toDictionary() throws -> [String : Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        return jsonObject as? [String : Any]
    }
}
