import ModelHike
import ModelHike_Blueprints

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
        var env = Environment.debug
        env.blueprints.add(OfficialBlueprintFinder())

        env.containersToOutput = ["APIs"]

        //for debugging
        //config.flags.fileGeneration = true

        //        config.events.onBeforeRenderFile = { filename, context in
        //            if filename.lowercased() == "MonitoredLiveAirport".lowercased() {
        //                print("rendering \(filename)")
        //            }
        //
        //            return true
        //        }
        //
        //        config.events.onBeforeParseTemplate = { templatename, context in
        //            if templatename.lowercased() == "entity.validator.teso".lowercased() {
        //                print("rendering \(templatename)")
        //            }
        //        }
        //
        //        config.events.onBeforeExecuteTemplate = { templatename, context in
        //            if templatename.lowercased() == "entity.validator.teso".lowercased() {
        //                print("rendering \(templatename)")
        //            }
        //        }
        //
        //        config.events.onStartParseObject = { objname, pInfo in
        //            print(objname)
        //            if objname.lowercased() == "airport".lowercased() {
        //                pInfo.ctx.debugLog.flags.lineByLineParsing = true
        //            } else {
        //                pInfo.ctx.debugLog.flags.lineByLineParsing = false
        //            }
        //        }

        //continue run
        let pipeline = Pipelines.codegen
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
