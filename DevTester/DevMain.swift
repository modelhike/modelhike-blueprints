import DiagSoup_Blueprints
import DiagSoup

@main
struct Development {
    static func main() async {
        do {
            try await runCodebaseGeneration()
        } catch {
            print(error)
        }
    }
    
    static func runCodebaseGeneration() async throws {
        let env = Environment.debug
        
        let pipeline = Pipelines.codegen
        env.blueprints.add(OfficialBlueprintFinder())
        try await pipeline.run(using: env)
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
