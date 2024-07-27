//
//  ResourceLoader.swift
//
//
//  Created by Hari on 24/07/24.
//

import Foundation
import DiagSoup

public class DSTemplateLoader : ResourceTemplateLoader {
    
    public init(command: String, with ctx: Context) {
        super.init(command: command, bundle: Bundle.module, with: ctx)
    }
}
