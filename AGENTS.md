# AGENTS.md — ModelHike Blueprints: Full Project Analysis

> **Purpose:** This document is a comprehensive reference for AI agents and developers. It captures the full architecture, conventions, and current state of this repository so analysis does not need to be re-done from scratch. Keep this file updated when making structural changes.
>
> **Last Updated:** 2026-02-25

---

## Table of Contents

1. [What Is This Repository?](#1-what-is-this-repository)
2. [Ecosystem Context](#2-ecosystem-context)
3. [Repository Structure](#3-repository-structure)
4. [Swift Package Layout](#4-swift-package-layout)
5. [The `OfficialBlueprintFinder` (only Swift source)](#5-the-officialblueprintfinder-only-swift-source)
6. [DevTester — Local Development Runner](#6-devtester--local-development-runner)
7. [Template Languages](#7-template-languages) — `.ss`, `.teso`, and `{{...}}` in filenames
8. [Blueprint 1: `api-nestjs-monorepo`](#8-blueprint-1-api-nestjs-monorepo)
9. [Blueprint 2: `api-springboot-monorepo`](#9-blueprint-2-api-springboot-monorepo)
10. [Shared Model Concepts](#10-shared-model-concepts)
11. [Static Library Files (NestJS)](#11-static-library-files-nestjs)
12. [Current State & Known Gaps](#12-current-state--known-gaps)
13. [How to Run / Test Locally](#13-how-to-run--test-locally)
14. [Conventions & Patterns to Maintain](#14-conventions--patterns-to-maintain)

---

## 1. What Is This Repository?

`modelhike-blueprints` is a **Swift Package Manager library** that provides the official, pre-built **code-generation blueprints** for the ModelHike framework.

A **blueprint** is a collection of templates and orchestration scripts that, when combined with a domain model input, produce a complete runnable backend project. This package does not contain the generation engine — it only contains the blueprint definitions (templates + scripts).

**Two blueprints are currently available:**
| Blueprint ID | Target Stack |
|---|---|
| `api-nestjs-monorepo` | NestJS (TypeScript) — REST APIs, CQRS pattern, MongoDB |
| `api-springboot-monorepo` | Spring Boot 3.x (Java) — GraphQL APIs, reactive WebFlux, MongoDB |

---

## 2. Ecosystem Context

This package is one piece of a larger system:

```
modelhike/              ← The core engine (Swift package, sibling directory)
    └── provides: ModelHike, ResourceBlueprintFinder, BlueprintFinder protocol,
                  Pipeline, Pipelines, PipelineConfig, OutputConfig,
                  InlineModelLoader, InlineModel, InlineCommonTypes, etc.

modelhike-blueprints/   ← THIS REPOSITORY
    └── provides: OfficialBlueprintFinder (wraps ResourceBlueprintFinder with bundle)
                  + all .teso template files and .ss orchestration scripts
```

`Package.swift` currently uses a **local path dependency** to `../modelhike`. The remote GitHub reference (`https://github.com/modelhike/modelhike`) is commented out, meaning the two packages must coexist as siblings locally.

```swift
// Package.swift
dependencies: [
    //.package(url: "https://github.com/modelhike/modelhike", from: "0.1.0"),
    .package(path: "../modelhike")
],
```

---

## 3. Repository Structure


```
modelhike-blueprints/
├── Package.swift                          # SPM manifest (Swift 6.0, macOS 13+, iOS 16+)
├── README.md                              # Brief README listing available blueprints
├── LICENSE                                # MIT License (copyright 2024 modelhike)
├── .gitignore
│
├── Sources/                               # Library target root
│   ├── OfficialBlueprintFinder.swift      # THE only Swift source file in the library
│   └── Resources/
│       └── blueprints/
│           ├── api-nestjs-monorepo/       # Blueprint: NestJS monorepo
│           │   ├── main.ss                # Orchestration script
│           │   ├── *.teso                 # Template files
│           │   ├── _root_/                # Static files copied verbatim to output root
│           │   └── libs/                  # Static TypeScript library files
│           │
│           └── api-springboot-monorepo/   # Blueprint: Spring Boot monorepo
│               ├── main.ss                # Orchestration script
│               ├── *.teso                 # Template files
│               ├── _root_/                # Static files (Dockerfile, gradle wrapper, etc.)
│               ├── base-service-files/    # Templates for per-module infrastructure files
│               ├── base-service-files-src/# Templates for App.java, AppConfig.java
│               ├── entity-files/          # Templates for entity model/crud (conditionally included)
│               │   ├── model/
│               │   └── crud/
│               ├── entity-graphql-api/    # GraphQL controller + http test file
│               ├── entity-rest-api/       # REST controller (exists but disabled in main.ss)
│               └── embedded-type-files/   # Templates for embedded/value types
│
└── DevTester/                             # Executable target for local dev testing
    ├── DevMain.swift                      # @main entry — runs code generation pipeline
    └── Environment.swift                  # Output path configs (debug/production)
```

---

## 4. Swift Package Layout

**Package Name:** `ModelHike.Blueprints`

**Platforms:** macOS 13, iOS 16, tvOS 13, watchOS 6

**Products:**
- `.library(name: "ModelHike.Blueprints", targets: ["ModelHike_Blueprints"])` — the distributable library
- `.executable(name: "DevTester_Blueprints", targets: ["DevTester_Blueprints"])` — dev runner (not for distribution)

**Targets:**

| Target | Type | Path | Notes |
|---|---|---|---|
| `ModelHike_Blueprints` | Library | `Sources/` | Bundles all `Resources/` via `.copy("Resources/")` |
| `DevTester_Blueprints` | Executable | `DevTester/` | Dev-only. Imports `ModelHike_Blueprints` + `ModelHike` |

> ⚠️ A test target (`ModelHike_Blueprints_Tests`) is commented out. No automated tests exist.

---

## 5. The `OfficialBlueprintFinder` (only Swift source)

**File:** `Sources/OfficialBlueprintFinder.swift`

This is the **entire Swift source code** of the library — one `public actor`.

```swift
public actor OfficialBlueprintFinder: BlueprintFinder {
    let resources: ResourceBlueprintFinder

    public var blueprintsAvailable: [String] {
        return ["api-nestjs-monorepo", "api-springboot-monorepo"]
    }

    public func hasBlueprint(named name: String) -> Bool { ... }
    public func blueprint(named name: String, with pInfo: ParsedInfo) async throws -> any Blueprint { ... }

    public init() {
        resources = ResourceBlueprintFinder(bundle: Bundle.module)
    }
}
```

**Key points:**
- Conforms to `BlueprintFinder` protocol (defined in `ModelHike` package)
- Uses `Bundle.module` (the SPM-generated resource bundle accessor) to access `.teso` and `.ss` files
- Delegates actual file-loading to `ResourceBlueprintFinder` (from `ModelHike` package)
- Adding a new blueprint = add a folder under `Sources/Resources/blueprints/` AND add the name to `blueprintsAvailable`

---

## 6. DevTester — Local Development Runner

**Files:** `DevTester/DevMain.swift`, `DevTester/Environment.swift`

This is a **standalone executable** for manually triggering code generation during development.

### `Environment.swift`

Defines two `OutputConfig` configurations (using `PipelineConfig` from the `ModelHike` package):

| Environment | Output Path |
|---|---|
| `debug` | A local dev/test folder path (relative path via `LocalPath`) |
| `production` | A separate stable output path |

Currently `debug` is always used (`Environment.debug`). Update `Environment.swift` to point the output paths to your desired locations before running.

### `DevMain.swift`

The `@main` struct `Development`:

1. Creates a `PipelineConfig` from `Environment.debug`
2. Appends `OfficialBlueprintFinder()` to `env.blueprints`
3. Sets `env.containersToOutput = ["APIs"]` — restricts generation to the `APIs` container
4. Runs `Pipelines.codegen.run(using: env)`

**Debug hooks (all currently commented out):**
- `onBeforeRenderTemplateFile` — can enable `lineByLineParsing` per-file
- `onBeforeRenderFile` — called before each file render
- `onBeforeParseTemplate` — called before template parse
- `onBeforeExecuteTemplate` — called before template execution
- `onStartParseObject` — called per model object during parse

**`inlineModel()` helper (defined but not used in `runCodebaseGeneration`):**
- Provides an example inline model definition (a `Registry` entity with various property types)
- Illustrates the domain model syntax: container → module → entity → properties
- Also shows `InlineCommonTypes` with `CodedValue`, `Reference`, `ExtendedReference`, `Audit`

---

## 7. Template Languages

### 7.1 `.ss` — SoupyScript (Orchestration Scripts)

Used only in `main.ss`. Every line is a **statement** (no prefix needed). Multi-line string content is written after `>` inside `set-str` blocks.

**Available statements:**

| Statement | Description |
|---|---|
| `announce "msg"` | Print a log message |
| `set var = expr` | Variable assignment |
| `set-str var > ... end-set` | Multi-line string assignment (content lines prefixed with `>`) |
| `render-file "name" as "filename"` | Render a `.teso` template to a named file |
| `render-folder "folder" to dir` | Render all `.teso` files in a folder to a directory |
| `copy-folder "folder"` | Copy static files verbatim to output |
| `for X in Y` / `end-for` | Loop |
| `if / else-if / else / end-if` | Conditional |
| `func name()` / `end-func` | Function definition |
| `call funcname()` | Function call |
| `fatal-error "msg"` | Halt generation with error |

**Context variables available in `.ss`:**
- `@container` — top-level model container
- `@container.modules` — list of modules
- `@container.default-module` — the first/default module
- `module.entities`, `module.embedded-types`
- `entity | apis` — derived list of API operations for an entity

**Filter expressions (pipe syntax):**
- `module.name | lowercase + kebabcase` → `"registryManagement"` → `"registry-management"`
- `module.name | package-case + lowercase` → `"registry_management"`
- `module_pkg_name | replace(".", "/")` → converts package path to directory path

---

### 7.2 `.teso` — Template Soup (Code Templates)

The **inverse** of SoupyScript: content lines are output verbatim; lines prefixed with `:` are control statements. Template expressions use `{{...}}` syntax.

**Control syntax (`: prefix`):**

| Syntax | Description |
|---|---|
| `: set var = expr` | Variable assignment |
| `: set-str var` / `: end-set` | Multi-line string assignment |
| `: for X in Y` / `: end-for` | Loop |
| `: if / :else-if / :else / :end-if` | Conditional |
| `: func name(params)` / `: end-func` | Template function definition |
| `: call funcname(params)` | Template function call |
| `: spaceless` / `: end-spaceless` | Suppress all whitespace in enclosed block |

**Interpolation:**
- `{{variable}}` — output variable value
- `{{var | filter}}` — apply named filter
- `\( expr )` — alternate interpolation form (seen in controller template for path strings)

**Filters available in templates:**

| Filter | Effect |
|---|---|
| `lowercase` | lowercase string |
| `lowercase + kebabcase` | lowercase kebab-case |
| `plural` | pluralize word |
| `lowercase + plural` | lowercase plural |
| `upperFirst` | Capitalize first letter |
| `lowerFirst` | Lowercase first letter |
| `split-camel-to-kebabcase` | CamelCase → kebab-case |
| `package-case + lowercase` | Java package name style |
| `replace(".", "/")` | String replacement |
| `typename` | Resolve TypeScript/Java type name from property |
| `graphql-typename` | Resolve GraphQL type name from property |
| `get-last-recursive-prop(entityName)` | Resolve final property in a nested prop mapping |
| `filter-string` | Generate a query filter assignment block (NestJS list queries) |
| `apis` | Get list of API operations for an entity |
| `sample-json` | Generate a sample JSON payload from an entity (used in test/HTTP files) |
| `sample-query` | Generate a sample query string from a list API's query params |

**Special context variables:**
- `@mock.object-id` — generates a mock MongoDB ObjectId string (used in HTTP client templates)

**Special context variables in templates:**
- `@container` — the top-level container
- `@container.modules` — all modules
- `@container.commons` — all common types
- `@loop.last` — true if current loop iteration is the last
- `entity`, `module`, `api`, `property` — loop variables

**Template frontmatter — SpringBoot only (`-----...-----` at top of file):**

Three supported directives:

| Directive | Meaning |
|---|---|
| `/include-for : X in Y` | Iterate over collection before applying include-if |
| `/include-if : condition` | Only generate this file if condition is true |
| `/file-name : expr` | Override output filename (can use template expressions) |

Example from `CustomLogicApi.java.teso`:
```
-----
/include-for : api in apis
/include-if : api.is-mutation-by-custom-logic or api.is-get-by-custom-logic
/file-name : {{api.name}}.java
-----
```
This generates one file **per matching API** (not per entity), with a dynamic filename derived from the API name. This is the mechanism that creates separately-named files like `ActivateRegistry.java`, `GetByStatus.java`, etc. for custom logic operations.

**Firecracker emoji `🔥` in templates:** Used as a placeholder for literal spaces inside `spaceless` blocks (where real spaces would be trimmed). The engine converts `🔥` → ` ` in output.

---

### 7.3 `{{...}}` in Physical Filenames on Disk

Template expressions can appear **in the actual filename of a `.teso` file** on disk — not just inside file content. The engine resolves these expressions at generation time using the current loop context before writing the output file.

This is the primary mechanism used with `render-folder` in the SpringBoot blueprint. When the engine processes a folder, it iterates over all `.teso` files and evaluates any `{{...}}` in their names to derive the output filename.

**Examples from the repo:**

| File on disk | Resolves to (example) |
|---|---|
| `{{entity.name}}.java.teso` | `Registry.java` |
| `{{entity.name}}Input.java.teso` | `RegistryInput.java` |
| `{{entity.name}}Repository.java.teso` | `RegistryRepository.java` |
| `{{entity.name}}Controller.java.teso` | `RegistryController.java` |
| `Create{{entity.name}}Command.java.teso` | `CreateRegistryCommand.java` |
| `Delete{{entity.name}}Command.java.teso` | `DeleteRegistryCommand.java` |
| `List{{entity.name \| plural}}Query.java.teso` | `ListRegistriesQuery.java` |
| `{{embedded-type.name}}.java.teso` | `CodedValue.java` |
| `{{embedded-type.name}}Input.java.teso` | `CodedValueInput.java` |

**Key rules:**
- Filters work the same way as inside template content (e.g., `| plural`, `| lowercase`)
- The context variable used must be in scope for the current `render-folder` call (e.g., `entity.name` is valid while iterating entities)
- This mechanism is **distinct** from the `/file-name` frontmatter directive — filename expressions on disk apply to every file in the folder uniformly, while `/file-name` overrides the name per-iteration for a single template file

---

## 8. Blueprint 1: `api-nestjs-monorepo`

### Overview

Generates a complete **NestJS TypeScript monorepo** with:
- CQRS pattern (`@nestjs/cqrs`)
- REST APIs
- MongoDB via native driver
- Yup validation
- JWT auth infrastructure (wired but not enforced — guards commented out)
- Soft delete + audit trail pattern
- Per-module pagination on list queries
- PlantUML class diagrams for documentation

### `main.ss` Frontmatter

```
-----
Product-name : GenProduct
Company-name : WowCompany
-----
```

These become template variables `{{Product-name}}` and `{{Company-name}}` (default placeholder values — replaced by the actual project values at generation time).

### `main.ss` Generation Flow

```
1. render "typescript.domain.classes"     → /libs/domain-models/domain.entities.ts
2. render "typescript.common.classes"     → /libs/domain-models/common.classes.ts
3. render "yup.domain.classes"            → /libs/validation/yup.domain.entities.schema.ts
4. render "yup.common.classes"            → /libs/validation/yup.common.classes.schema.ts

For each MODULE:
  For each ENTITY:
    For each API (create/update/delete/getById/list):
      → /apps/<module>/<entity>/crud/<operation>.ts  (CQRS command/query file)

    → /apps/<module>/<entity>/controller.ts           (REST controller)
    → /apps/<module>/<entity>/controller.test.ts      (Controller test)
    → /apps/<module>/<entity>/module.ts               (NestJS module)
    → /apps/<module>/<entity>/validator.ts            (Entity validator)
    → /apps/<module>/<entity>/requests.http           (HTTP client file)

  → /apps/<module>/src/app.module.ts                  (Root AppModule)
  → /apps/<module>/src/main.ts                        (Bootstrap)
  → /apps/<module>/tsconfig.app.json
  → /apps/<module>/jest.config.js
  → /docs/class-diag/<module>.puml                    (PlantUML diagram)

copy-folder "libs"                                    → /libs/ (static TS files)

render "docker-compose.yml"                           → /docker-compose.yml
render "package.json"                                 → /package.json
render "nest-cli.json"                                → /nest-cli.json
render "jest.config.ts"                               → /jest.config.ts
```

### Generated Output Structure

```
(output root)/
├── libs/
│   ├── auth/auth.token.ts              ← JWT session class (static)
│   ├── db/db.client.ts                 ← MongoDB CRUD wrapper (static)
│   ├── includes/
│   │   ├── audit.ts                    ← Audit class (static)
│   │   ├── constants.ts                ← UserRoles, etc. (static)
│   │   ├── internal.response.ts        ← InternalResponse wrapper (static)
│   │   └── external.response.ts        ← HTTP response with NestJS exceptions (static)
│   ├── validation/yup.validator.ts     ← Generic Yup validate helper (static)
│   ├── domain-models/
│   │   ├── domain.entities.ts          ← Generated TypeScript entity classes
│   │   └── common.classes.ts           ← Generated common type classes
│   └── validation/
│       ├── yup.domain.entities.schema.ts  ← Generated Yup schemas
│       └── yup.common.classes.schema.ts   ← Generated common Yup schemas
│
├── apps/
│   └── <module-kebab>/
│       ├── src/
│       │   ├── <entity-kebab>/
│       │   │   ├── crud/
│       │   │   │   ├── create.<entity>.ts
│       │   │   │   ├── update.<entity>.ts
│       │   │   │   ├── delete.<entity>.ts
│       │   │   │   ├── get.<entity>.byId.ts
│       │   │   │   └── list.<entity-plural>.ts
│       │   │   ├── controller.ts
│       │   │   ├── controller.test.ts
│       │   │   ├── module.ts
│       │   │   ├── validator.ts
│       │   │   └── requests.http
│       │   ├── app.module.ts
│       │   └── main.ts
│       ├── tsconfig.app.json
│       └── jest.config.js
│
├── docs/class-diag/<module>.puml
├── package.json
├── nest-cli.json
├── jest.config.ts
├── docker-compose.yml
│
└── (from _root_/ static copy):
    ├── .env, .env.dev, .env.qa, .env.stage, .env.test
    ├── .dockerignore, .gitignore, .prettierrc.json
    ├── Dockerfile
    ├── eslint.config.mjs
    ├── tsconfig.json, tsconfig.build.json
    └── tests/common-initialization.js
```

### Supported API Types (NestJS)

| API Type | Generated File | CQRS Class |
|---|---|---|
| `is-create` | `create.<entity>.ts` | `Create<Entity>Command` + handler |
| `is-update` | `update.<entity>.ts` | `Update<Entity>Command` + handler |
| `is-delete` | `delete.<entity>.ts` | `Delete<Entity>Command` + handler |
| `is-get-by-id` | `get.<entity>.byId.ts` | `Get<Entity>Query` + handler |
| `is-list` | `list.<entity-plural>.ts` | `Find<Entity>ByQuery` + handler |
| anything else | — | `fatal-error` halts generation |

### Key NestJS Template Patterns

**CQRS Command/Query pattern:**
Each file exports both the Command/Query class AND its Handler. The command/query holds the logic in a `run()` method; the handler delegates to `command.run()`.

**Controller list endpoint with dynamic query params:**
The controller template contains inline template functions (`getQueryParamString`, `getQueryParamNameAsQueryInput`, `getQuerySplitStatementsIfAny`) to handle multi-value filter params (comma-separated values split into `Set<T>`).

**Bootstrap (`app.main.teso`) — generated `main.ts` features:**
- Reads `PORT` from `process.env.PORT`, defaults to `{{module.port}}`
- Validates `DATABASE_URL` and `DATABASE_NAME` env vars are set at startup (throws if missing)
- `bodyParser.json({ limit: '16mb' })` for large payloads
- `app.setGlobalPrefix("api")` — all routes prefixed with `/api`
- `ValidationPipe` with `transform: true` (auto type coercion; `forbidUnknownValues` commented out)
- URI versioning via `VersioningType.URI` (no default version set — must be declared per controller)
- Wildcard CORS: `allowedHeaders: '*', origin: '*'`
- Calls `app.startAllMicroservices()` before `app.listen(PORT)`

**HTTP client file (`requests.http`):**
Generated per entity as a REST client invocation file. Uses `@mock.object-id` for sample IDs and `api.entity | sample-json` filter to populate request bodies with sample data from the model. For list APIs, conditionally adds `api | sample-query` as URL query string.

**Integration test file (`controller.test.ts`):**
Not just a skeleton — generates a **full integration test suite** using `supertest` for each API type, with both happy-path and failure-path test cases. Tests mock `CommandBus` and `QueryBus` using `jest.spyOn`. Uses `api.entity | sample-json` to generate realistic test payloads. Hardcoded mock IDs: `existingId = '6673bd8c0fcfd8a21bd15300'`, `nonExistingId = '000000000000000000000001'`.

**Response pattern:**
```
Controller method → CommandBus/QueryBus.execute() → InternalResponse
→ ExternalResponse.command(response) / ExternalResponse.query(response)
→ throws Success | BadRequestException | FailureException (NestJS HttpException subclasses)
```

**Soft delete:** All DB operations filter `'audit.del': false`. Delete sets `'audit.del': true`.

**Audit trail:** Automatic `crBy`, `crDt`, `upDt`, `upBy` fields on insert/update.

### NestJS Technology Stack (from `package.json.teso`)

| Package | Version | Purpose |
|---|---|---|
| `@nestjs/common,core` | ^10.3.9 | NestJS core |
| `@nestjs/cqrs` | ^10.2.7 | CQRS pattern |
| `@nestjs/config` | ^3.2.2 | Env config |
| `@nestjs/cache-manager` | ^2.2.2 | Caching |
| `mongodb` | ^6.7.0 | Native MongoDB driver |
| `yup` | ^1.4.0 | Schema validation |
| `rxjs` | ^7.8.1 | Reactive extensions |
| `typescript` | ^5.4.5 | TypeScript |
| `jest` | ^29.7.0 | Testing |
| `node` | >=20.14.0 | Runtime requirement |

---

## 9. Blueprint 2: `api-springboot-monorepo`

### Overview

Generates a complete **Spring Boot 3.x reactive Java monorepo** with:
- GraphQL APIs (queries, mutations, subscriptions)
- Reactive programming via Project Reactor (Mono/Flux)
- MongoDB via `spring-boot-starter-data-mongodb-reactive`
- Spring for GraphQL with WebSocket-based subscriptions
- WebFlux (non-blocking, required for subscriptions)
- Lombok for boilerplate reduction
- Per-module Gradle subproject structure

### Frontmatter Variables (in `main.ss`)

```
api-base-path : /api/v1
```

Plus model-driven variables like `company-pkg-prefix`, `module.port`, `db-uri`, `allowed-cors-url`.

### `main.ss` Generation Flow

```
For each MODULE:
  set working_dir = "/"

  For each ENTITY (and DTOs):
    Validate all APIs are supported (fatal-error on unknown type)

    render-folder "entity-files"       → /base-services/<module>/src/<pkg>/<entity-pkg>/
      (includes model/, crud/ — conditionally by api type via frontmatter)
    render-folder "entity-graphql-api" → /base-services/<module>/src/<pkg>/<entity-pkg>/
    // entity-rest-api is DISABLED (commented out)

  For each EMBEDDED TYPE:
    render-folder "embedded-type-files" → /base-services/<module>/src/<pkg>/types/

  render-folder "base-service-files"     → /base-services/<module>/
  render-folder "base-service-files-src" → /base-services/<module>/src/<pkg>/
  call render-graphQl-schema()           → /base-services/<module>/resources/graphql/<module>.graphqls

  render-file "plantuml.classes"         → /docs/class-diag/<module>.puml

(root static files from _root_/ are NOT explicitly copied in main.ss;
 they are handled by the framework's root file copying mechanism)
```

### Generated Output Structure

```
(output root)/
├── base-services/
│   └── <module-kebab>/
│       ├── src/
│       │   └── <pkg/path>/          (e.g., com/wowcompany/registrymanagement/)
│       │       ├── App.java          ← SpringBoot @SpringBootApplication entry
│       │       ├── AppConfig.java    ← @EnableWebFlux, CORS, DateTime scalar config
│       │       └── <entity-pkg>/    (e.g., registry/)
│       │           ├── model/
│       │           │   ├── <Entity>.java           ← @Document + @Data (Lombok)
│       │           │   ├── <Entity>Input.java       ← Input DTO
│       │           │   └── <Entity>Repository.java  ← ReactiveMongoRepository
│       │           └── crud/
│       │               ├── Create<Entity>Command.java   (if create api exists)
│       │               ├── Update<Entity>Command.java   (if update api exists)
│       │               ├── Delete<Entity>Command.java   (if delete api exists)
│       │               ├── Get<Entity>ByIdQuery.java    (if getById api exists)
│       │               ├── List<Entity>sQuery.java      (if list api exists)
│       │               ├── ListCustom<Entity>sQuery.java (if list-by-custom-logic)
│       │               ├── CustomLogicApi.java           (if mutation-by-custom-logic)
│       │               └── CustomLogicListApi.java       (if list-by-custom-logic)
│       │           └── <Entity>Controller.java  ← GraphQL @Controller
│       │       └── types/
│       │           ├── <EmbeddedType>.java
│       │           └── <EmbeddedType>Input.java
│       ├── resources/
│       │   ├── application.yml
│       │   └── graphql/<module>.graphqls   ← Generated GraphQL schema
│       ├── build.gradle
│       └── settings.gradle
│
├── docs/class-diag/<module>.puml
│
└── (from _root_/ static):
    ├── settings.gradle               ← Includes all base-services subprojects
    ├── Dockerfile
    ├── docker-compose-apps.yml       ← Per-module containers (basic env vars)
    ├── docker-compose-base-services.yml ← Per-module containers WITH config-repo
    ├── gradlew, gradlew.bat
    └── gradle/wrapper/gradle-wrapper.*
```

### Supported API Types (SpringBoot)

| API Type | Java Annotation | Generated Files | Notes |
|---|---|---|---|
| `is-create` | `@MutationMapping` | `Create<Entity>Command.java` | |
| `is-update` | `@MutationMapping` | `Update<Entity>Command.java` | |
| `is-delete` | `@MutationMapping` | `Delete<Entity>Command.java` | Returns `Mono<Void>` |
| `is-get-by-id` | `@QueryMapping` | `Get<Entity>ByIdQuery.java` | |
| `is-list` | `@QueryMapping` | `List<Entity>sQuery.java` | `repository.findAll()` |
| `is-list-by-custom-props` | `@QueryMapping` | `<ApiName>Query.java` (via `/file-name`) | Spring Data derived query `findByX[And/Or]Y(...)` |
| `is-get-by-custom-logic` | `@QueryMapping` | `<ApiName>.java` (via `/file-name`) | Stub: `//TODO Implement this`, returns `null` |
| `is-list-by-custom-logic` | `@QueryMapping` | `<ApiName>.java` (via `/file-name`) | Stub: `//TODO Implement this`, returns `null` |
| `is-mutation-by-custom-logic` | `@MutationMapping` | `<ApiName>.java` (via `/file-name`) | Stub: `//TODO Implement this`, returns `null` |
| `is-push-data` | `@SubscriptionMapping` | (in Controller) | `ConnectableFlux` subscription |
| `is-push-datalist` | `@SubscriptionMapping` | (in Controller) | Same pattern as push-data |
| anything else | — | — | `fatal-error` halts generation |

**Custom logic stubs:** `CustomLogicApi.java.teso` and `CustomLogicListApi.java.teso` generate intentional TODO stubs. These are placeholders — the developer is expected to implement them. The file is named after the API (e.g., `ActivateUser.java`) via the `/file-name` frontmatter directive.

**`api.is-and-condition-for-properties-involved`:** The `list-by-custom-props` API type has this boolean flag controlling whether Spring Data's derived query joins properties with `And` or `Or`:
- `true` → `findByNameAndStatus(name, status)`
- `false` → `findByNameOrStatus(name, status)`

This flag affects both `{{entity.name}}Repository.java.teso` (interface method signature) and `ListCustom...Query.java.teso` (the component delegating to it).

### Conditional File Inclusion (Template Frontmatter)

SpringBoot templates use frontmatter to only generate a file when a specific API type exists:

```
-----
/include-for : api in apis
/include-if : api.is-create
-----
```

This means e.g., `Create<Entity>Command.java` is only generated if the entity has a `create` API.

### Embedded Types (SpringBoot)

Embedded types (`embedded-type-files/`) are Java value types that are **not MongoDB documents** — they have no `@Document` annotation, only `@Data` (Lombok). They are used as nested fields inside entities.

- `{{embedded-type.name}}.java.teso` — plain `@Data` class with property fields
- `{{embedded-type.name}}Input.java.teso` — matching Input DTO for mutations
- Package: `{{module_pkg_name}}.types`
- Context variable: `embedded-type.name`, `embedded-type.properties` (same property API as entities)

### GraphQL Schema Generation

The `graphql-schema-module.teso` template generates a complete `.graphqls` file:
- `scalar DateTime`
- `type Subscription { ... }` (if push APIs exist)
- `type Mutation { ... }` (if mutation APIs exist)
- `type Query { ... }` (if query APIs exist)
- `type <Entity> { ... }` for each entity + DTO
- `input <Entity>Input { ... }` (if mutations exist)
- `type <EmbeddedType> { ... }` and `input <EmbeddedType>Input { ... }` for embedded types

Properties are marked `!` (non-null) if `property.is-required`.

### GraphQL Subscription Architecture

When push APIs exist, the entity's `Controller.java` gets:
- `private FluxSink<Entity> entityStream` and `ConnectableFlux<Entity> entityPublisher`
- `@PostConstruct initialize()` — wires up the Flux publisher
- `@SubscriptionMapping` method returning `ConnectableFlux`
- On create mutations: `entityStream.next(entity)` pushes new records to subscribers

### SpringBoot Technology Stack (from `build.gradle.teso`)

| Dependency | Purpose |
|---|---|
| `spring-boot-starter-data-mongodb-reactive` | Reactive MongoDB |
| `spring-boot-starter-graphql` | Spring for GraphQL |
| `spring-boot-starter-webflux` | Non-blocking HTTP + WebSocket |
| `spring-boot-starter-rsocket` | RSocket support |
| `graphql-java-extended-scalars:22.0` | DateTime scalar |
| `joda-time:2.12.5` | Date utilities |
| `lombok` | `@Data`, boilerplate reduction |
| Java version | **17** |
| Spring Boot version | **3.0.5** |

---

## 10. Shared Model Concepts

Both blueprints consume the same model input. These are the core model concepts:

### Container

Top-level object. Accessed as `@container` in templates.
- `@container.modules` — list of all modules
- `@container.commons` — shared common types
- `@container.default-module` — the first module (default)

### Module

Represents a microservice / bounded context.

Properties available in templates:
- `module.name` — e.g., `"Registry Management"`
- `module.entities` — list of domain entities
- `module.entities-and-dtos` — entities + DTOs combined
- `module.embedded-types` — value types embedded in entities
- `module.types` — all types in module
- `module.port` — HTTP port for this service
- `module.push-apis`, `module.mutation-apis`, `module.query-apis` — API groupings
- `module.has-push-apis`, `module.has-mutation-apis`, `module.has-query-apis`, `module.has-embedded-types` — boolean flags

### Entity / DTO

A domain object (maps to a MongoDB collection).

Properties available in templates:
- `entity.name` — PascalCase name, e.g., `"Registry"`
- `entity.properties` — list of properties
- `entity.given-name` — the name as given in the model
- `entity.has-any-apis`, `entity.has-push-apis` — boolean flags
- `entity | apis` — resolves the APIs for this entity

### Property

A field on an entity or type.

Predicates:
- `property.is-required` / optional
- `property.is-array`
- `property.is-string`, `.is-number`, `.is-bool`, `.is-date`, `.is-id`, `.is-any`, `.is-buffer`
- `property.is-reference`, `.is-extended-reference`, `.is-coded-value`
- `property.is-custom-type`, `.is-object`
- `property.has-attrib-oneOf` — the property has an enum constraint

Other:
- `property.name` — field name
- `property | typename` — TypeScript/Java type string
- `property | graphql-typename` — GraphQL type string
- `property.custom-type` — the type name if custom
- `property.attrib-oneOf` — the enum values if constrained

### Model DSL Syntax (from `inlineModel()` in DevMain.swift)

```
===
APIs
====
+ Registry Management        ← "+" declares a module named "Registry Management"


=== Registry Management ===

Registry                     ← entity name
========
* _id: Id                    ← required Id field
* name: String               ← required String
- desc: String               ← optional String
* status: CodedValue         ← required CodedValue (common type)
* condition: CodedValue[1..*]← required array of CodedValue
* speciality: CodedValue
- author: Reference@StaffRole← optional Reference with role annotation
- audit: Audit (backend)     ← optional Audit, backend-only (not in generated client types)
```

**Modifiers:**
- `*` = required
- `-` = optional
- `[1..*]` = array (min 1 element)
- `(backend)` = not exposed in API / client code
- `@RoleName` = reference role annotation

### Built-in Common Types

These are first-class in the model system (from `getCommonTypes()` in DevMain.swift):

| Type | Fields |
|---|---|
| `CodedValue` | `vsRef`, `code`, `display` |
| `Reference` | `ref`, `type` (opt), `display` |
| `ExtendedReference` | `ref`, `type` (opt), `display`, `info` (opt), `infoType` (opt), `avatar` (opt), `linkRef` (opt), `linkType` (opt) |
| `Audit` | `ver`, `crBy`, `crDt`, `upDt`, `upBy`, `srcId`, `srcApp`, `del` |

### API Operations (from model)

APIs are declared in the model. Common types checked in templates:

| Predicate | Meaning |
|---|---|
| `api.is-create` | Create operation |
| `api.is-update` | Update operation |
| `api.is-delete` | Delete operation |
| `api.is-get-by-id` | Get single by ID |
| `api.is-list` | List with pagination |
| `api.is-list-by-custom-props` | List filtered by entity properties |
| `api.is-get-by-custom-logic` | Custom single-item getter |
| `api.is-list-by-custom-logic` | Custom list getter |
| `api.is-mutation-by-custom-logic` | Custom mutation |
| `api.is-push-data` | GraphQL subscription (single item) |
| `api.is-push-datalist` | GraphQL subscription (list) |

API properties:
- `api.name` — operation name
- `api.type` — type identifier string
- `api.path` — URL path segment (e.g., `:id` for REST)
- `api.query-params` — list of query params for list operations
- `api.cqrs-classname`, `api.cqrs-file-import-path`, `api.cqrs-handler-name` — set dynamically in `main.ss`
- `api.has-path`, `api.properties-involved`, `api.custom-params`, `api.return-type`, `api.input-type`

---

## 11. Static Library Files (NestJS)

These files in `Sources/Resources/blueprints/api-nestjs-monorepo/libs/` are **not templates** — they are static TypeScript files copied verbatim into the generated project.

### `libs/db/db.client.ts` — MongoDB Wrapper

Full-featured MongoDB client class with:

| Method | Description |
|---|---|
| `connect(collectionName)` | Connect to DB; reads `DATABASE_URL` + `DATABASE_NAME` from env |
| `insert(payload)` | Insert with auto audit fields (crBy, crDt, upDt, upBy, del=false) |
| `update({id, payload})` | Update by ID with audit update fields |
| `updatebyQuery({query, payload})` | Update matching documents |
| `softDelete(id)` | Set `audit.del = true` |
| `findById(id, removeAudit?)` | Find by ObjectId, filters `audit.del: false` |
| `findAllByPage({page, limit, query})` | Paginated find with total count |
| `batchedGetByIds(ids: Set<string>)` | Bulk fetch by ObjectId set |
| `findByQuery(query)` | Aggregate pipeline query |
| `activate(id)` | Set `active: true` + audit |
| `deactivate(id)` | Set `active: false` + audit |
| `hardDeleteOneByQuery({query})` | Physical delete by query |
| `hardDeleteOneById(_id)` | Physical delete by ID |
| `totalActiveCount()` | Count non-deleted documents |
| `queryBasedCount(query)` | Count by query |
| `close()` | Close MongoDB connection |
| `pingCheck()` | Ping the database |

**Soft delete convention:** All reads filter `'audit.del': false`. Delete sets it to `true`. Data is never physically deleted through normal operations.

### `libs/includes/internal.response.ts` — InternalResponse

Internal bus object passed between command/query and controller:

| Factory Method | Meaning |
|---|---|
| `InternalResponse.result(data)` | Successful data response |
| `InternalResponse.success()` | Successful command (no data) |
| `InternalResponse.noData()` | 404-like, not found |
| `InternalResponse.emptyData()` | Empty result (not an error) |
| `InternalResponse.badRequest(msg)` | 400 validation failure |
| `InternalResponse.failure()` | 504 generic failure |
| `InternalResponse.exception(error)` | Wrap a caught error |

### `libs/includes/constants.ts` — UserRoles

Static `UserRoles` class with predefined roles:
- `UserRoles.SUPER_ADMIN = 'superadmin'`
- `UserRoles.EMPLOYEE = 'employee'`
- `UserRoles.roles` — array of all roles
- `UserRoles.isSuperAdmin(role)` — boolean check

### `libs/includes/audit.ts` — Audit

TypeScript class mirroring the `Audit` common type:
- `ver: string`, `crBy: Reference`, `crDt: Date`, `upDt: Date`, `upBy: Reference`, `srcId: string`, `srcApp: string`, `del: boolean`

### `libs/validation/yup.validator.ts` — YupSchemaValidator

```typescript
YupSchemaValidator.validate(schema, payload)
```
Uses `abortEarly: false` — collects ALL validation errors (not just the first). Returns `error.errors` array on failure, `null` on success.

### `libs/includes/external.response.ts` — ExternalResponse

Converts `InternalResponse` to NestJS HTTP responses by throwing `HttpException` subclasses:
- `Success` (extends `HttpException`) — thrown on successful responses
- `BadRequestException` — 400
- `FailureException` — 500 (or derived status code)

App codes: 2000 (query ok), 2001 (command ok), 4000 (bad request), 5000 (failure).

### `libs/auth/auth.token.ts` — UserSessionJwt

JWT session class. **Note:** The constructor body is entirely commented out — `UserSessionJwt` does NOT currently parse JWT payload. Fields (`userRef`, `userDisp`, `loginId`, `role`, `userAvatar`, `type`) are declared but never populated from the token.

```typescript
constructor(payload: any) {
  // All parsing commented out
}
```

This means `token.getUserRef()` returns an empty `Reference` object (no actual user info). Authentication enforcement via `AuthGuard` in controllers is also commented out.

---

## 12. Current State & Known Gaps

### What Works
- Both blueprints (`api-nestjs-monorepo`, `api-springboot-monorepo`) are functional and generate complete project skeletons
- NestJS blueprint: full CRUD with CQRS, pagination, filtering, soft delete, audit
- SpringBoot blueprint: full CRUD + custom query types + GraphQL subscriptions via reactive Flux
- PlantUML diagram generation for all modules in both blueprints
- Swift 6.0 full concurrency (migrated, latest commit)

### Known Gaps / Incomplete Items

| Area | Status |
|---|---|
| **JWT parsing in `auth.token.ts`** | Constructor body is fully commented out; `UserSessionJwt` never parses the JWT. Auth data is not populated. |
| **Auth guards in NestJS** | `@UseGuards(AuthGuard())` / `@UseGuards(RolesGuard)` are commented out in generated controllers and modules. Authentication is not enforced at runtime. |
| **AuthModule import** | `//import { AuthModule }` commented out in `app.module.teso` and `entity.module.teso` |
| **REST API for SpringBoot** | `entity-rest-api/` folder exists with a REST `{{entity.name}}Controller.java.teso` and `Apis.http.teso`, but `render-folder "entity-rest-api"` is commented out in `main.ss`. Only GraphQL is generated. |
| **SpringBoot validation** | Validation calls are commented out in generated Java controllers (`// await Validator.validateForCreate(payload)`) |
| **Test target** | The `ModelHike_Blueprints_Tests` target in `Package.swift` is commented out. No automated tests. |
| **DevTester inline model** | `inlineModel()` helper in `DevMain.swift` is defined but never called. The actual model source is external (from `ModelHike` pipeline). |
| **Remote package dependency** | `Package.swift` uses `path: "../modelhike"` (local). The GitHub URL is commented out. Both packages must be siblings locally. |
| **Springboot `@EnableMongoRepositories`** | In `App.java.teso`, the annotation `@EnableMongoRepositories` is used but its import is missing from the template. |
| **NestJS module providers** | In `entity.module.teso`, Handler classes are listed in the `imports` array (line: `{{api.cqrs-handler-name}},` inside `imports: [`), which is incorrect — handlers should be in `providers`. |
| **SpringBoot custom logic stubs** | `CustomLogicApi.java.teso` and `CustomLogicListApi.java.teso` generate `return null; //TODO Implement this` — these are intentional scaffolds requiring manual implementation. |
| **SpringBoot docker-compose duality** | Two compose files exist: `docker-compose-apps.yml.teso` (simple) and `docker-compose-base-services.yml.teso` (includes `SPRING_CONFIG_LOCATION` for config repo). The intended use-case distinction is not documented. |
| **`ListCustom...Query` debug log** | `ListCustom{{entity.name | plural}}Query.java.teso` has a stray `System.out.println("Number of OR flights: " + count)` debug line in the generated code. |

---

## 13. How to Run / Test Locally

### Prerequisites

- Swift 6.0+ (Xcode 16+ or swift toolchain)
- The sibling `modelhike` package at `../modelhike` (same parent directory)
- A domain model file understood by the `ModelHike` pipeline

### Build

```bash
swift build
```

### Run Development Tester

```bash
swift run DevTester_Blueprints
```

This runs `DevMain.swift`:
1. Loads `Environment.debug` config (output path configured in `Environment.swift`)
2. Registers `OfficialBlueprintFinder`
3. Filters to `containersToOutput = ["APIs"]`
4. Runs the `Pipelines.codegen` pipeline
5. Output files are written to the configured path

### Debugging

Uncomment any of the event hooks in `DevMain.swift` to get granular debugging:

```swift
// Line-by-line parsing for a specific file:
config.events.onBeforeRenderTemplateFile = { filename, templateName, pInfo in
    if filename.is("some.file.ts") {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
    return true
}
```

---

## 14. Conventions & Patterns to Maintain

### Adding a New Blueprint

1. Create folder: `Sources/Resources/blueprints/<blueprint-id>/`
2. Add `main.ss` orchestration script
3. Add `.teso` template files
4. Add any static files (no `.teso` extension)
5. Place root-level static files in `_root_/` subdirectory
6. Register in `OfficialBlueprintFinder.swift`:
   ```swift
   public var blueprintsAvailable: [String] {
       return ["api-nestjs-monorepo", "api-springboot-monorepo", "<new-blueprint-id>"]
   }
   ```

### Template File Naming Conventions

- Templates: descriptive dot-separated names + `.teso` (e.g., `entity.create.command.teso`)
- Script: always `main.ss`
- Static files: normal filenames (no `.teso`)
- Template expressions `{{...}}` can appear in the physical filename on disk and are resolved at generation time (see section 7.3 for full details and examples)

### `.teso` Syntax Rules

- Lines starting with `:` are code; everything else is output
- Use `🔥` as a non-trimmed space placeholder inside `spaceless` blocks
- Template functions are defined/called within the same file or called from `.ss`
- Frontmatter (`-----...-----`) at file top for conditional inclusion (SpringBoot pattern)

### `.ss` Script Rules

- All lines are statements
- Multi-line strings use `set-str ... > content lines ... end-set`
- Content lines in `set-str` must be prefixed with `>` (SoupyScript inversion)
- Functions use `func name()` / `end-func`
- Support `fatal-error` to halt generation on unsupported model configurations

### Model-Driven Variable Naming

- Variables use `kebab-case` with hyphens (e.g., `module.has-push-apis`, `api.is-create`)
- This is the internal DSL convention from the `ModelHike` package
- Do not use camelCase or underscore_case for model property accessors
