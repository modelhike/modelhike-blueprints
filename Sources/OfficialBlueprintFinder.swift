//
//  ResourceLoader.swift
//
//
//  Created by Hari on 24/07/24.
//

import Foundation
import DiagSoup

public class OfficialBlueprintFinder : ResourceBlueprintFinder {
    public override func getListOfblueprintsAvailable() -> [String] {
        return [
            "api-nestjs-monorepo",
            "api-springboot-monorepo"
        ]
    }
    
    public init() {
        super.init(bundle: Bundle.module)
    }
}
