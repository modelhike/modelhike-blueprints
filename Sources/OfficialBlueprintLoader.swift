//
//  ResourceLoader.swift
//
//
//  Created by Hari on 24/07/24.
//

import Foundation
import DiagSoup

public class OfficialBlueprintLoader : ResourceBlueprintLoader {
    
    public init(blueprint: String, with ctx: Context) {
        super.init(blueprint: blueprint, bundle: Bundle.module, with: ctx)
    }
}
