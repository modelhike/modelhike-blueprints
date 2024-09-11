import DiagSoup_Blueprints
import DiagSoup

@main
struct Development {
    static func main() {
        do {
            try genNestJs()
        } catch {
            print(error)
        }
    }
    
    static func genNestJs() throws {
        let ws = Workspace();
                
        ws.basePath = SystemFolder.documents.path / "diagsoup"
        //ws.debugLog.flags.fileGeneration = true
        
        try ws.loadSymbols([.typescript, .mongodb_typescript])
        
        //let modelRepo = LocalFileModelLoader(path: ws.basePath, with: ws.context)
        let modelRepo = InlineModelLoader(with: ws.context) {
            InlineModel {
                """
                # Registry Management

                Registry
                ========
                * _id: Id
                * name: String
                - desc: String
                * status: CodedValue
                * condition: CodedValue[1..*]
                * speciality: CodedValue
                - author: Reference@StaffRole
                - audit: Audit (backend)
                """
            }
            
            getCommonTypes()
        }
        
        try ws.loadModels(from: modelRepo)
        
        //let templatesPath = ws.basePath / "_gen.templates"
        //let templatesRepo = LocalFileTemplateLoader(command: "nestjs-monorepo", path: templatesPath, with: ws.context)
        let templatesRepo = OfficialBlueprintLoader(command: "nestjs-monorepo", with: ws.context)
        
        ws.generateCodebase(usingBlueprintsFrom: templatesRepo)
    }
    
    private static func getCommonTypes() -> InlineCommonTypes {
        return InlineCommonTypes {
                """
                CodedValue
                ==========
                * vsRef: String
                * code: String
                * display: String
                
                Reference
                =========
                * ref: String
                - type: String
                * display: String
                
                ExtendedReference
                =================
                * ref: String
                - type: String
                * display: String
                - info: Any
                - infoType: String
                - avatar: String
                - linkRef: String
                - linkType: String
                
                Audit
                ========
                - ver: String
                - crBy: Reference
                - crDt: Date
                - upDt: Date
                - upBy: Reference
                - srcId: String
                - srcApp: String
                - del: Bool
                """
            }
    }
}
