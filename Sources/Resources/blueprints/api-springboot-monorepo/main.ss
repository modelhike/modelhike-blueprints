-----
api-base-path : /api/v1
-----

announce "Generating SpringBoot Reactive Apis (monorepo) ..."

for module in @container.modules
set working_dir = "/"

set module_folder_name = module.name| lowercase + kebabcase
set-str module_pkg_name
> {{company-pkg-prefix}}.{{module.name| package-case + lowercase}}
end-set
set module_folder_structure = module_pkg_name | replace(".", "/") //for creating java package structure

for entity in module.entities-and-dtos
set submodule_pkg_name = entity.name| package-case + lowercase
//set entity.folder_name = submodule_folder_name
set-str entity_pkg_name
> {{module_pkg_name}}.{{submodule_pkg_name}}
end-set

set apis = entity | apis

set-str entity_dir
> /base-services/{{module_folder_name}}/src/{{module_folder_structure}}/{{submodule_pkg_name}}/
end-set

render-folder "entity-files" to entity_dir
//render-folder "entity-rest-api" to entity_dir
render-folder "entity-graphql-api" to entity_dir

end-for // entity for loop

----------- embedded types -------------
for embedded-type in module.embedded-types
set-str embedded_type_pkg_name
> {{module_pkg_name}}.types
end-set

set-str embedded_type_dir
> /base-services/{{module_folder_name}}/src/{{module_folder_structure}}/types/
end-set

render-folder "embedded-type-files" to embedded_type_dir

end-for // embedded type for loop

set-str  module_dir
> /base-services/{{module_folder_name}}/
end-set

render-folder "base-service-files" to module_dir

set-str module_src_dir
> /base-services/{{module_folder_name}}/src/{{module_folder_structure}}/
end-set

render-folder "base-service-files-src" to module_src_dir

call render-graphQl-schema()

// generate documentation
set working_dir = "/docs/class-diag"
set-str file_name
> {{module_folder_name}}.puml
end-set

render-file "plantuml.classes" as file_name

end-for // modules for loop

-------------- functions area -----------------------------------

func render-graphQl-schema()
    // generate graphQL schema
    set-str working_dir
    > /base-services/{{module_folder_name}}/resources/graphql
    end-set

    set-str file_name
    > {{module_folder_name}}.graphqls
    end-set

    render-file "graphql-schema-module" as file_name
end-func
