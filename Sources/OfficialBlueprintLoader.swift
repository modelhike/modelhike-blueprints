//
//  ResourceLoader.swift
//
//
//  Created by Hari on 24/07/24.
//

import Foundation
import DiagSoup

public class OfficialBlueprintLoader : ResourceBlueprintLoader {
    
    public init(command: String, with ctx: Context) {
        super.init(command: command, bundle: Bundle.module, with: ctx)
    }
}
