-----
Product-name : Task Board App
symbols-to-load : typescript
-----

announce "Generating React App UI ..."

render-folder "_root_" to "/"

set working_dir = "/src/types"

for module in @container.modules
for entity in module.entities-and-dtos
set-str file_name
> {{entity.name}}.ts
end-set
render-file "entity.type" as file_name
end-for
end-for

set working_dir = "/src/data"

render-file "mock.data" as "mockData.ts"

set working_dir = "/src/services"

for module in @container.modules
for service in module.services
set-str file_name
> {{service.name}}.ts
end-set
render-file "service.functions" as file_name
end-for
end-for

set working_dir = "/src/components"

for module in @container.modules
for view in module.ui-views
set-str file_name
> {{view.name}}.tsx
end-set
render-file "ui.component" as file_name
end-for
end-for

set working_dir = "/src"

render-file "app.tsx" as "App.tsx"
render-file "main.tsx" as "main.tsx"
