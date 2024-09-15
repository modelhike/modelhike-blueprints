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
        let modelRepo = inlineModel(ws)
        
        try ws.loadModels(from: modelRepo)
        
        //let templatesPath = ws.basePath / "_gen.templates"
        //let templatesRepo = LocalFileTemplateLoader(command: "nestjs-monorepo", path: templatesPath, with: ws.context)
        let templatesRepo = OfficialBlueprintLoader(blueprint: "nestjs-monorepo", with: ws.context)
        
        ws.generateCodebase(container: "APIs", usingBlueprintsFrom: templatesRepo)
    }
    
    private static func inlineModel(_ ws: Workspace) -> InlineModelLoader {
        return InlineModelLoader(with: ws.context) {
            InlineModel {
                """
                ===
                APIs
                ====
                + Registry Management
                
                
                === Registry Management ===
                
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
    }
    
    private static func getCommonTypes() -> InlineCommonTypes {
        return InlineCommonTypes {
                """
                === Commons ===
                
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
