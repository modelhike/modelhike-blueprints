//
//  ResourceLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import ModelHike

public actor OfficialBlueprintFinder: BlueprintFinder {
    let resources: ResourceBlueprintFinder
    
    public var blueprintsAvailable: [String] {
        return [
            "api-nestjs-monorepo",
            "api-springboot-monorepo",
        ]
    }
    
    public func hasBlueprint(named name: String) -> Bool {
        blueprintsAvailable.contains(name)
    }

    public func blueprint(named name: String, with pInfo: ModelHike.ParsedInfo) async throws -> any ModelHike.Blueprint {
        return try await resources.blueprint(named: name, with: pInfo)
    }
    
    public init() {
        resources = ResourceBlueprintFinder(bundle: Bundle.module)
    }
}
