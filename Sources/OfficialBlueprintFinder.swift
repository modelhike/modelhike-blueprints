//
//  ResourceLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import ModelHike

public class OfficialBlueprintFinder: ResourceBlueprintFinder {
    public override func getListOfblueprintsAvailable() -> [String] {
        return [
            "api-nestjs-monorepo",
            "api-springboot-monorepo",
        ]
    }

    public init() {
        super.init(bundle: Bundle.module)
    }
}
