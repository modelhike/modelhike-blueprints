import ModelHike

enum Environment {
    static var debug: OutputConfig {
        var env = PipelineConfig()
        
        env.basePath = LocalPath(relativePath: "modelhike", basePath: SystemFolder.documents.path)

        return env
    }
    
    static var production: OutputConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "modelhike", basePath: SystemFolder.documents.path)

        return env
    }
}

