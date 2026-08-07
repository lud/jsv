# Changelog

All notable changes to this project will be documented in this file.

## [0.22.0] - 2026-08-07

### 🚀 Features

- Implement uniqueItems for Decimal (_lud_)

### 🐛 Bug Fixes

- Raise explicit message on defschema without :properties (_lud_)

### 🚜 Refactor

- Extract test suite generation into JSV.TestSuiteGenerator (_Ludovic Dem_)

### 🧪 Testing

- Render floats as erlang would decode them when generating test suite (_lud_)
- Updated JSON Schema Test Suite (_lud_)
- Updated JSON Schema Test Suite and updated conformity tests (_lud_)

### ⚙️ Miscellaneous Tasks

- Document invalid JSON files in JSON Schema Test Suite (_lud_)

## [0.21.2] - 2026-07-10

### 🐛 Bug Fixes

- Ignore httpc cache chmod tests on windows (_Ludovic Dem_)
- Add missing type: object on arprops schema helper (_lud_)

### 📚 Documentation

- Added missing docs for public API (_lud_)

## [0.21.1] - 2026-07-06

### 🚀 Features

- Allow to define @doc above defschema to document json_schema/0 generated function (_lud_)

## [0.21.0] - 2026-07-05

### 🐛 Bug Fixes

- Prevent infinite recursion in cross ref schemas (_lud_)
- [**breaking**] JSV.Resolver.Httpc security defaults (no redirects, TLS verification, private atomic cache, size/timeout limits) (_lud_)
- Bound regex backtracking cost in pattern and patternProperties matching (_lud_)
- Support dynamicAnchor in id-less root schemas and fail gracefully on malformed keywords (_lud_)

### 📚 Documentation

- Document internal resolver security considerations (_lud_)

### 🧪 Testing

- Updated JSON Schema Test Suite (_lud_)
- Updated JSON Schema Test Suite (_lud_)

## [0.20.0] - 2026-06-26

### 🚀 Features

- Removed NimbleOptions dependency and changed internal options to use maps (_lud_)

### 🚜 Refactor

- Skip tracking casts and unevaluated paths when schemas do not need it (_lud_)

## [0.19.6] - 2026-06-25

### 🐛 Bug Fixes

- Support unicode general categories in pattern/patternProperties (_lud_)

### 🧪 Testing

- Updated JSON Schema Test Suite (_lud_)

## [0.19.5] - 2026-06-15

### 🐛 Bug Fixes

- Properly handle Draft-7 style anchor IDs (_lud_)

### 🧪 Testing

- Updated JSON Schema Test Suite (_lud_)

## [0.19.4] - 2026-06-07

### 🐛 Bug Fixes

- Fixed nested anchor resolution without root namespace (_lud_)

## [0.19.3] - 2026-05-30

### 🐛 Bug Fixes

- Allow module-based schemas in schema helpers typespecs (_lud_)

## [0.19.2] - 2026-05-29

### 🐛 Bug Fixes

- Make local resolver work on Windows (#95) (_Ludovic Dem_)
- Reject +/- prefixes on 'date' format (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema test suite (_lud_)
- Fix compilation warnings for Elixir 1.20 (_lud_)

## [0.19.1] - 2026-05-13

### 🚀 Features

- Return better stacktraces in builder warnings (_lud_)

## [0.19.0] - 2026-05-10

### 🚀 Features

- [**breaking**] New cast system see https://hexdocs.pm/jsv/002-api-changes-v0-19.html (#90) (_Ludovic Dem_)
- [**breaking**] Converted schema presets to new cast system (_lud_)
- Added schema build warnings on atom casters (#91) (_Ludovic Dem_)
- Pass raw schema to casters at build time (_lud_)
- Added the aprops and arprops helpers to cast properties schemas to atom keys (_lud_)
- Removed the deprecated schema presets in JSV.Schema (_lud_)
- [**breaking**] Support Decimal 3.0 and drop support for Poison (_lud_)

### 🐛 Bug Fixes

- MultipleOf with Decimal support (_lud_)
- Ignore examples keyword when scanning schema (_lud_)
- Nullable() will now add nil to enums (_lud_)

### 📚 Documentation

- Document build_key usage with refs (_lud_)
- Reference drop of Poison support in migration guide (_lud_)

### ⚙️ Miscellaneous Tasks

- Added roadmap section to readme (_lud_)
- Refactor of the JSON Schema test suite generators (_lud_)
- Simplify built-in casts output syntax (_lud_)

## [0.18.3] - 2026-04-21

### 🐛 Bug Fixes

- Fixed schema scanning around non-schemas like properties (_lud_)
- Allow to dereference numeric pointers from maps in refs (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema Test Suite (_lud_)

## [0.18.2] - 2026-04-19

### 🐛 Bug Fixes

- Allow root $ref to resolve against root $id in Draft-7 (_lud_)

### 📚 Documentation

- Fixed documentation for httpc resolver (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema test suite (_lud_)

## [0.18.1] - 2026-04-08

### 🚀 Features

- Return a BuildError instead of raising a RuntimeError for :invalid_properties (_Bruce Williams_)

## [0.18.0] - 2026-04-02

### 🚀 Features

- [**breaking**] Removed support for deprecated schema/0 export from schema modules (_lud_)

## [0.17.1] - 2026-03-19

### 🐛 Bug Fixes

- Revert undesired regex compilation change (_lud_)

### ⚙️ Miscellaneous Tasks

- Relax idna version requirements (_lud_)

## [0.17.0] - 2026-03-19

### 🚀 Features

- New return type signature for custom error formatters (_lud_)
- [**breaking**] Read and consume module attributes for defschema/3 (_lud_)

### 🧪 Testing

- Upgraded JSON Schema Test Suite (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated license to Apache-2.0 (_lud_)

## [0.16.0] - 2026-01-20

### 🚀 Features

- [**breaking**] Changed schema titles for JSV.KeywordError, JSV.ValidationError and JSV.ValidationUnit (_lud_)

## [0.15.2] - 2026-01-19

### 🐛 Bug Fixes

- Fixed type error on serialization optional values (_lud_)

## [0.15.1] - 2026-01-06

### 🚀 Features

- Added :as_root option for normalize_collect (_lud_)

### 🐛 Bug Fixes

- Do not add description to schema with defschema/3 if nil (_lud_)

## [0.15.0] - 2026-01-06

### 🚀 Features

- Added JSV.Schema.normalize_collect to generate self-contained schemas from modules (_lud_)
- Added the nullable/1 schema helper (_Jaden_)

### 📚 Documentation

- Fixed docs for the optional helper (_lud_)

## [0.14.0] - 2025-12-30

### 🚀 Features

- Allow to use schema helpers with import JSV and defschema/3 (_lud_)
- Added json serialization skip option in optional() properties (_lud_)

## [0.13.1] - 2025-11-26

### 🐛 Bug Fixes

- Invalidate empty labels in hostname validation (_lud_)

## [0.13.0] - 2025-11-25

### 🚀 Features

- Relax additional properties in error schemas (_lud_)
- Support the @skip_keys attribute for structs created with defschema (_lud_)
- New hostname validator based on :idna (new JSON Schema suite tests) (_lud_)

## [0.12.0] - 2025-11-19

### 🚀 Features

- Support normalizing structs into non-map values in the Normalizer (_lud_)
- Added support for collecting additionalProperties in structs (_lud_)

## [0.11.5] - 2025-11-12

### 🐛 Bug Fixes

- Relax Poison dependency version constraints (_lud_)

### 📚 Documentation

- Document function groups in main JSV module (_lud_)

## [0.11.4] - 2025-10-23

### 🐛 Bug Fixes

- Ignore all error values from Code.ensure_compiled (_lud_)

## [0.11.3] - 2025-10-23

### 🐛 Bug Fixes

- Fixed module-based schema loading in Elixir 1.19 (_lud_)

## [0.11.2] - 2025-10-13

### 📚 Documentation

- Fixed doc on schema preset helpers (_lud_)

## [0.11.0] - 2025-09-16

### 🚀 Features

- [**breaking**] ABNF parsers are now automatically enabled (_lud_)

### 🧪 Testing

- Updated JSON Schema Test Suite (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated README.md (_lud_)

## [0.10.1] - 2025-08-11

### 🚀 Features

- Export required keys from generated struct modules (_lud_)

### ⚙️ Miscellaneous Tasks

- Fix JSON tests for elixir 1.17 (_lud_)

## [0.10.0] - 2025-07-10

### 🚀 Features

- Define and expect schema modules to export json_schema/0 instead of schema/0 (_lud_)
- Allow to call defschema with a list of properties (_lud_)
- Added the defschema/3 macro to define schemas as submodules (_lud_)

### 🐛 Bug Fixes

- Ensure defschema with keyword syntax supports module-based properties (_lud_)

## [0.9.0] - 2025-07-05

### 🚀 Features

- Provide a schema representing normalized validation errors (_lud_)
- Deprecated the schema composition API in favor of presets (_lud_)

### 🐛 Bug Fixes

- Emit a build error with empty oneOf/allOf/anyOf (_lud_)
- Reset errors when using a detached validator (_lud_)
- Ensure casts are applied after all validations (_lud_)
- Revert default normalized error to atoms (_lud_)

### ⚙️ Miscellaneous Tasks

- Define titles for normal validation error schemas (_lud_)

## [0.8.1] - 2025-06-29

### ⚙️ Miscellaneous Tasks

- Export the locals_without_parens formatter opts for public macros (_lud_)

## [0.8.0] - 2025-06-23

### 🚀 Features

- Declare formatting support from main JSON codec (_lud_)
- Added the JSV.validate! bang functions (_lud_)
- Added explicit error when a sub schema is not buildable (_lud_)
- Export JSV.resolver_chain/1 for integration in 3rd parties (_lud_)
- [**breaking**] Defschema does not automatically define $id anymore (_lud_)
- Added string_to_number and string_to_boolean casters (_lud_)
- Return sub errors when oneOf has no matches (_lud_)
- Order sub-errors by ascending item index in array validation (_lud_)
- Added ability to build only a nested schema or multiple schemas (_lud_)
- Expose the map extensions helpers (_lud_)
- Added the prewalk traverse utility for schema normalization (_lud_)
- [**breaking**] Error normalizer will now sort error by instanceLocation (_lud_)
- [**breaking**] Changed caster tag of defschema to 0 (_lud_)
- Allow custom formats to validate other types than strings (_lud_)
- Provide a function to create reference from a list of path segments (_lud_)

### 🐛 Bug Fixes

- Ensure keys are json-pointer encoded in instanceLoction in errors (_lud_)
- Return meaningful error for unknow keys in :required in defschema (_lud_)
- Fixed typespec on JSV.build_key! (_lud_)
- Fixed typespec and argument name in Builder.build! (_lud_)

### 🚜 Refactor

- Renamed Schema.override/2 to Schema.merge/2 (_lud_)
- Defined different typespecs for normal schema and native schema (_lud_)
- Build error will now be raised with a proper stacktrace (_lud_)
- Removed useless accumulation of atoms when normalizing schemas (_lud_)
- [**breaking**] Changed order of arguments for Normalizer.normalize/3 (_lud_)
- Renamed build_root to to_root as it is not building validators (_lud_)

### 📚 Documentation

- Rework Decimal support limitations (_lud_)

### 🧪 Testing

- Verify that unknown formats are ignored when formats assertion is disabled (_lud_)

### ⚙️ Miscellaneous Tasks

- Clarify defschema error when no properties are given (_lud_)
- Fix warning when Poison.EncodeError is not defined (_lud_)
- Updated JSON Schema Test Suite (_lud_)
- Renamed keycast module attribute to jsv_keycast in defschema (_lud_)
- Provide correct line/column in debanged functions (_lud_)
- Allow to customize Inspect for Builder and Resolver (_lud_)
- Fix Elixir 1.19 warnings (_lud_)

## [0.7.2] - 2025-05-08

### 🚀 Features

- Added the non_empty_string schema helper (_lud_)
- Atom enums will use string_to_atom to support compile-time builds (_lud_)

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema Test Suite (_lud_)
- Enhanced JSTS updater (_lud_)
- Fixed warning on code when Decimal is missing (_lud_)

## [0.7.1] - 2025-04-27

### 🐛 Bug Fixes

- Fixed hex package definition (_lud_)

## [0.7.0] - 2025-04-27

### 🚀 Features

- Mail_address dependency is no longer used (_lud_)
- Validation support for Decimal (_lud_)

### 📚 Documentation

- Updated doc examples with generated code (_lud_)

### 🧪 Testing

- Enable tests for the 'uuid' format (_lud_)
- Enable tests for the 'hostname' format (_lud_)
- Enable tests for all uri/iri/pointer formats (_lud_)

### ⚙️ Miscellaneous Tasks

- Changed JSON schema test suite updater (_lud_)

## [0.6.3] - 2025-04-13

### ⚙️ Miscellaneous Tasks

- Fix missing file in hex package breaking installs (_lud_)

## [0.6.2] - 2025-04-13

### 🚀 Features

- Added Jason/Poison/JSON encoder implementations for JSV.NValidationError (_lud_)

## [0.6.1] - 2025-04-13

### ⚙️ Miscellaneous Tasks

- Use mix_version for release process (_lud_)

## [0.6.0] - 2025-04-13

### 🚀 Features

- Resolvers do not need to normalize schemas anymore (_lud_)
- Added support to override existing vocabularies (_lud_)
- Schema definition helpers do not enforce a Schema struct anymore (_lud_)
- Provide a generic JSON normalizer for data and schemas (_lud_)
- Allow resolvers to mark schemas as normalized (_lud_)
- [**breaking**] Use jsv-cast keyword in schemas for struct and cast functions (_lud_)

### 🐛 Bug Fixes

- Removed conversion to string in codec format_to_iodata (_lud_)

### 📚 Documentation

- Fix documentation grammar and typos (_lud_)
- Organize docs sidebar in categories (_lud_)

### ⚙️ Miscellaneous Tasks

- Update Elixir Github workflow (#17) (_Ludovic Dem_)
- Use absolute path for JSTS ref file (_lud_)

## [0.5.1] - 2025-03-28

### 🐛 Bug Fixes

- Fixed compilation with Mix.install (_lud_)

### ⚙️ Miscellaneous Tasks

- Release v0.5.1 (_lud_)

## [0.5.0] - 2025-03-25

### 🚀 Features

- Added JSV.Resolver.Local to resolve disk stored schemas (_lud_)
- Special error format for additionalProperties:false (_lud_)
- Provide correct schemaLocation in all errors (_lud_)
- Added defschema_for to use different modules for schema and struct (_lud_)
- Provide ordered JSON encoding with native JSON modules (_lud_)

### 🐛 Bug Fixes

- Check presence of JSON module in CI (_lud_)

### 🧪 Testing

- Make JSON codecs easier to test (_lud_)
- Fixed assertions for JSON codec on old OTP versions (_lud_)

### ⚙️ Miscellaneous Tasks

- Refactored schema normalization (_lud_)
- Removed unused alias (_lud_)
- Use readmix to generate formats docs (_lud_)

## [0.4.0] - 2025-02-08

### 🚀 Features

- Support module-based schemas with structs (_lud_)

## [0.3.0] - 2025-01-08

### 🚀 Features

- Added a default resolver using static schemas (_lud_)

### 🐛 Bug Fixes

- Upgrade abnf_parsec to correctly parse IRIs and IRI references (_lud_)

## [0.2.0] - 2025-01-03

### 📚 Documentation

- Document atom conversion (_lud_)
- Document functions with doc and spec (_lud_)

## [0.1.0] - 2025-01-01

