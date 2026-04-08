# Changelog

All notable changes to this project will be documented in this file.

## [0.18.1] - 2026-04-08

### 🚀 Features

- Return a BuildError instead of raising a RuntimeError for :invalid_properties

## [0.18.0] - 2026-04-02

### 🚀 Features

- [**breaking**] Removed support for deprecated schema/0 export from schema modules

## [0.17.1] - 2026-03-19

### 🐛 Bug Fixes

- Revert undesired regex compilation change

### ⚙️ Miscellaneous Tasks

- Relax idna version requirements

## [0.17.0] - 2026-03-19

### 🚀 Features

- New return type signature for custom error formatters
- [**breaking**] Read and consume module attributes for defschema/3

### 🧪 Testing

- Upgraded JSON Schema Test Suite

### ⚙️ Miscellaneous Tasks

- Updated license to Apache-2.0

## [0.16.0] - 2026-01-20

### 🚀 Features

- [**breaking**] Changed schema titles for JSV.KeywordError, JSV.ValidationError and JSV.ValidationUnit

## [0.15.2] - 2026-01-19

### 🐛 Bug Fixes

- Fixed type error on serialization optional values

## [0.15.1] - 2026-01-06

### 🚀 Features

- Added :as_root option for normalize_collect

### 🐛 Bug Fixes

- Do not add description to schema with defschema/3 if nil

## [0.15.0] - 2026-01-06

### 🚀 Features

- Added JSV.Schema.normalize_collect to generate self-contained schemas from modules
- Added the nullable/1 schema helper

### 📚 Documentation

- Fixed docs for the optional helper

## [0.14.0] - 2025-12-30

### 🚀 Features

- Allow to use schema helpers with import JSV and defschema/3
- Added json serialization skip option in optional() properties

## [0.13.1] - 2025-11-26

### 🐛 Bug Fixes

- Invalidate empty labels in hostname validation

## [0.13.0] - 2025-11-25

### 🚀 Features

- Relax additional properties in error schemas
- Support the @skip_keys attribute for structs created with defschema
- New hostname validator based on :idna (new JSON Schema suite tests)

## [0.12.0] - 2025-11-19

### 🚀 Features

- Support normalizing structs into non-map values in the Normalizer
- Added support for collecting additionalProperties in structs

## [0.11.5] - 2025-11-12

### 🐛 Bug Fixes

- Relax Poison dependency version constraints

### 📚 Documentation

- Document function groups in main JSV module

## [0.11.4] - 2025-10-23

### 🐛 Bug Fixes

- Ignore all error values from Code.ensure_compiled

## [0.11.3] - 2025-10-23

### 🐛 Bug Fixes

- Fixed module-based schema loading in Elixir 1.19

## [0.11.2] - 2025-10-13

### 📚 Documentation

- Fixed doc on schema preset helpers

## [0.11.0] - 2025-09-16

### 🚀 Features

- [**breaking**] ABNF parsers are now automatically enabled

### 🧪 Testing

- Updated JSON Schema Test Suite

### ⚙️ Miscellaneous Tasks

- Updated README.md

## [0.10.1] - 2025-08-11

### 🚀 Features

- Export required keys from generated struct modules

### ⚙️ Miscellaneous Tasks

- Fix JSON tests for elixir 1.17

## [0.10.0] - 2025-07-10

### 🚀 Features

- Define and expect schema modules to export json_schema/0 instead of schema/0
- Allow to call defschema with a list of properties
- Added the defschema/3 macro to define schemas as submodules

### 🐛 Bug Fixes

- Ensure defschema with keyword syntax supports module-based properties

## [0.9.0] - 2025-07-05

### 🚀 Features

- Provide a schema representing normalized validation errors
- Deprecated the schema composition API in favor of presets

### 🐛 Bug Fixes

- Emit a build error with empty oneOf/allOf/anyOf
- Reset errors when using a detached validator
- Ensure casts are applied after all validations
- Revert default normalized error to atoms

### ⚙️ Miscellaneous Tasks

- Define titles for normal validation error schemas

## [0.8.1] - 2025-06-29

### ⚙️ Miscellaneous Tasks

- Export the locals_without_parens formatter opts for public macros

## [0.8.0] - 2025-06-23

### 🚀 Features

- Declare formatting support from main JSON codec
- Added the JSV.validate! bang functions
- Added explicit error when a sub schema is not buildable
- Export JSV.resolver_chain/1 for integration in 3rd parties
- [**breaking**] Defschema does not automatically define $id anymore
- Added string_to_number and string_to_boolean casters
- Return sub errors when oneOf has no matches
- Order sub-errors by ascending item index in array validation
- Added ability to build only a nested schema or multiple schemas
- Expose the map extensions helpers
- Added the prewalk traverse utility for schema normalization
- [**breaking**] Error normalizer will now sort error by instanceLocation
- [**breaking**] Changed caster tag of defschema to 0
- Allow custom formats to validate other types than strings
- Provide a function to create reference from a list of path segments

### 🐛 Bug Fixes

- Ensure keys are json-pointer encoded in instanceLoction in errors
- Return meaningful error for unknow keys in :required in defschema
- Fixed typespec on JSV.build_key!
- Fixed typespec and argument name in Builder.build!

### 🚜 Refactor

- Renamed Schema.override/2 to Schema.merge/2
- Defined different typespecs for normal schema and native schema
- Build error will now be raised with a proper stacktrace
- Removed useless accumulation of atoms when normalizing schemas
- [**breaking**] Changed order of arguments for Normalizer.normalize/3
- Renamed build_root to to_root as it is not building validators

### 📚 Documentation

- Rework Decimal support limitations

### 🧪 Testing

- Verify that unknown formats are ignored when formats assertion is disabled

### ⚙️ Miscellaneous Tasks

- Clarify defschema error when no properties are given
- Fix warning when Poison.EncodeError is not defined
- Updated JSON Schema Test Suite
- Renamed keycast module attribute to jsv_keycast in defschema
- Provide correct line/column in debanged functions
- Allow to customize Inspect for Builder and Resolver
- Fix Elixir 1.19 warnings

## [0.7.2] - 2025-05-08

### 🚀 Features

- Added the non_empty_string schema helper
- Atom enums will use string_to_atom to support compile-time builds

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema Test Suite
- Enhanced JSTS updater
- Fixed warning on code when Decimal is missing

## [0.7.1] - 2025-04-27

### 🐛 Bug Fixes

- Fixed hex package definition

## [0.7.0] - 2025-04-27

### 🚀 Features

- Mail_address dependency is no longer used
- Validation support for Decimal

### 📚 Documentation

- Updated doc examples with generated code

### 🧪 Testing

- Enable tests for the 'uuid' format
- Enable tests for the 'hostname' format
- Enable tests for all uri/iri/pointer formats

### ⚙️ Miscellaneous Tasks

- Changed JSON schema test suite updater

## [0.6.3] - 2025-04-13

### ⚙️ Miscellaneous Tasks

- Fix missing file in hex package breaking installs

## [0.6.2] - 2025-04-13

### 🚀 Features

- Added Jason/Poison/JSON encoder implementations for JSV.NValidationError

## [0.6.1] - 2025-04-13

### ⚙️ Miscellaneous Tasks

- Use mix_version for release process

## [0.6.0] - 2025-04-13

### 🚀 Features

- Resolvers do not need to normalize schemas anymore
- Added support to override existing vocabularies
- Schema definition helpers do not enforce a Schema struct anymore
- Provide a generic JSON normalizer for data and schemas
- Allow resolvers to mark schemas as normalized
- [**breaking**] Use jsv-cast keyword in schemas for struct and cast functions

### 🐛 Bug Fixes

- Removed conversion to string in codec format_to_iodata

### 📚 Documentation

- Fix documentation grammar and typos
- Organize docs sidebar in categories

### ⚙️ Miscellaneous Tasks

- Update Elixir Github workflow (#17)
- Use absolute path for JSTS ref file

## [0.5.1] - 2025-03-28

### 🐛 Bug Fixes

- Fixed compilation with Mix.install

### ⚙️ Miscellaneous Tasks

- Release v0.5.1

## [0.5.0] - 2025-03-25

### 🚀 Features

- Added JSV.Resolver.Local to resolve disk stored schemas
- Special error format for additionalProperties:false
- Provide correct schemaLocation in all errors
- Added defschema_for to use different modules for schema and struct
- Provide ordered JSON encoding with native JSON modules

### 🐛 Bug Fixes

- Check presence of JSON module in CI

### 🧪 Testing

- Make JSON codecs easier to test
- Fixed assertions for JSON codec on old OTP versions

### ⚙️ Miscellaneous Tasks

- Refactored schema normalization
- Removed unused alias
- Use readmix to generate formats docs

## [0.4.0] - 2025-02-08

### 🚀 Features

- Support module-based schemas with structs

## [0.3.0] - 2025-01-08

### 🚀 Features

- Added a default resolver using static schemas

### 🐛 Bug Fixes

- Upgrade abnf_parsec to correctly parse IRIs and IRI references

## [0.2.0] - 2025-01-03

### 📚 Documentation

- Document atom conversion
- Document functions with doc and spec

## [0.1.0] - 2025-01-01

