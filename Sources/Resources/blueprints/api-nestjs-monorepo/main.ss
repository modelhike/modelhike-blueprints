-----
Product-name : GenProduct
Company-name : WowCompany
symbols-to-load : typescript, mongodb_typescript
-----

announce "Generating NestJs Apis (monorepo) ..."

set working_dir = "/libs/domain-models"

render-file "typescript.domain.classes" as "domain.entities.ts"
render-file "typescript.common.classes" as "common.classes.ts"

set working_dir = "/libs/validation"

render-file "yup.domain.classes" as "yup.domain.entities.schema.ts"
render-file "yup.common.classes" as "yup.common.classes.schema.ts"


for module in @container.modules
set module_folder_name = module.name| lowercase + kebabcase

for entity in module.entities
set submodule_folder_name = entity.given-name| lowercase + kebabcase
set entity.folder_name = submodule_folder_name

set apis = entity | apis

set-str working_dir
> /apps/{{module_folder_name}}/src/{{submodule_folder_name}}/crud
end-set

for api in apis

if api.is-create

	set-str file_name
	> create.{{entity.name | lowercase}}.ts
	end-set

	set-str classname
	> Create{{entity.name}}Command
	end-set

	set api.cqrs-classname = classname
	set-str api.cqrs-file-import-path
	> ./crud/create.{{entity.name | lowercase}}
	end-set

	render-file "entity.create.command" as file_name

else-if api.is-update

	set-str file_name
	> update.{{entity.name | lowercase}}.ts
	end-set

	set-str classname
	> Update{{entity.name}}Command
	end-set

	set api.cqrs-classname = classname
	set-str api.cqrs-file-import-path
	> ./crud/update.{{entity.name | lowercase}}
	end-set
	render-file "entity.update.command" as file_name

else-if api.is-delete

	set-str file_name
	> delete.{{entity.name | lowercase}}.ts
	end-set

	set-str classname
	> Delete{{entity.name}}Command
	end-set

	set api.cqrs-classname = classname
	set-str api.cqrs-file-import-path
	> ./crud/delete.{{entity.name | lowercase}}
	end-set
	render-file "entity.delete.command" as file_name

else-if api.is-get-by-id

	set-str file_name
	> get.{{entity.name | lowercase}}.byId.ts
	end-set

	set-str classname
	> Get{{entity.name}}Query
	end-set

	set api.cqrs-classname = classname
	set-str api.cqrs-file-import-path
	> ./crud/get.{{entity.name | lowercase}}.byId
	end-set
	render-file "entity.get.byid.query" as file_name

else-if api.is-list

	set-str file_name
	> list.{{entity.name | lowercase+plural}}.ts
	end-set

	set-str classname
	> Find{{entity.name}}ByQuery
	end-set

	set api.cqrs-classname = classname
	set-str api.cqrs-file-import-path
	> ./crud/list.{{entity.name | lowercase+plural}}
	end-set

	render-file "entity.get.all.query" as file_name

else
    fatal-error unknown api '{{api.name}}', with type '{{api.type}}'
end-if


end-for // apis for loop

set-str working_dir
> /apps/{{module_folder_name}}/src/{{submodule_folder_name}}
end-set

render-file "entity.controller" as "controller.ts"
render-file "entity.controller.testing" as "controller.test.ts"
render-file "entity.module" as "module.ts"

render-file "entity.validator" as "validator.ts"
render-file "api.invoke.rest.client" as "requests.http"


end-for // entity for loop

set-str working_dir
> /apps/{{module_folder_name}}/src/
end-set

render-file "app.module" as "app.module.ts"
render-file "app.main" as "main.ts"

set-str working_dir
> /apps/{{module_folder_name}}/
end-set

render-file "app.tsconfig.json" as "tsconfig.app.json"
render-file "app.jest.config.js" as "jest.config.js"

// generate documentation
set working_dir = "/docs/class-diag"
set-str file_name
> {{module_folder_name}}.puml
end-set

render-file "plantuml.classes" as file_name

end-for // modules for loop

set working_dir = "/"

copy-folder "libs"
//copy-folder "monorepo" to working_dir

//render-file "README.md"
render-file "docker-compose.yml"
render-file "package.json"
render-file "nest-cli.json"
render-file "jest.config.ts"
