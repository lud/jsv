# Changelog

All notable changes to this project will be documented in this file.

## [0.28.0] - 2026-11-19

**Smaller errors.** The per-child errors of `items`, `properties` and related keywords now carry `nil` as data instead of the whole array or object, and the errors of `anyOf`, `oneOf`, `allOf` and `if` no longer embed the root schema. Sending an error to another process, storing it in ETS or serializing it now copies much less data.

**`false` subschemas.** The specific message, like "additional properties are not allowed but found property 'b'", is now on the `boolean_schema` error of the rejected property or item, at level 10. With `JSV.normalize_error/2` and `min_error_level: 10`, it is reported at the instance location of that property or item (`#/b`) instead of its parent (`#`).

**Custom code matching on error args.**

- For `anyOf`, `oneOf`, `allOf` and `if` errors, the `ok_if_vctx`, `ok_if_subschema`, `err_if_vctx` and `after_err_vctx` args are replaced by `ok_if`, `err_if_errors` and `after_errors`.
- The `boolean_schema_false` arg is removed from the parent error. The rejected key is in the `key` arg of the child `boolean_schema` error.

**Custom vocabularies.** A level returned by `format_error/3` still takes precedence over the `level` arg. `JSV.Builder.build_sub!/4` accepts an `:error_formatter` option to format the error of a `false` subschema with the vocabulary's own message. The following functions are deprecated:

- `JSV.Validator.validate_in/6`, `JSV.Validator.validate_key/5` and `JSV.Validator.validate_in_detach/6`: the level argument is ignored. Use `validate_in/5`, `validate_key/4` and `validate_in_detach/5`.
- `JSV.ErrorFormatter.level_parent_reported/0`: no built-in error uses it anymore.

IDNA 8 is now accepted as a dependency.


### 🚀 Features

- [**breaking**] Set error levels in args and report false subschemas on the child (#167)

### 🐛 Bug Fixes

- Keep the container data out of per-child wrapper errors (#159) – by Lars Hesel Christensen
- Accept duplicates in 'required' keyword (#161) – by Lars Hesel Christensen
- Keep only errors and paths in anyOf/oneOf/allOf/if error args (#165)
- Report the index in draft 7 items list schemaLocation

### ⚡ Performance

- Validate object properties without intermediate lists or data copies – by Lars Hesel Christensen
- Set the subschema path once when validating a sub term – by Lars Hesel Christensen
- Check type lists without a closure – by Lars Hesel Christensen
- Upcase date and time strings only when they hold a lowercase separator – by Lars Hesel Christensen

## [0.27.0] - 2026-11-04

New `JSV.valid?/2` function: it returns a boolean and stops at the first error. It skips building errors and tracking the paths used to report them, so it is cheaper than `JSV.validate/3` when the errors are not needed. Cast functions are still called, because a failing cast makes the data invalid, but the cast data is not returned. Thanks to @larshesel for this contribution ([#155](https://github.com/lud/jsv/pull/155)).

`JSV.validate/3` is also faster: it executes 4% to 11% fewer instructions than in 0.26.2 on the library benchmarks, and more on schemas using `$ref` or module schemas.

**Custom vocabularies.** With `JSV.valid?/2`, the first error stops the whole validation. Keywords that test the result of a subschema and can accept the data that the subschema rejects, like `not`, `anyOf` or `contains`, must validate it with `JSV.Validator.validate_detach/4`, or with the new `JSV.Validator.validate_in_detach/6` for a property or array item. With `validate/3`, `validate_in/6` or `validate_as/4`, such keywords would wrongly reject data under `JSV.valid?/2`. Results with `JSV.validate/3` are unchanged. The `JSV.Vocabulary` documentation describes which function to use.

The `validators` and `opts` fields of the validation context moved to an internal `config` field. Read them with `JSV.Validator.ValidationContext.config/2`, for instance `ValidationContext.config(vctx, :opts)`.

### 🚀 Features

- Add JSV.valid?/2, a fail-fast validation mode (#155) – by Lars Hesel Christensen

### 🚜 Refactor

- Reduce fail-fast validator helpers to validate_detach and validate_in_detach

### ⚡ Performance

- Pin benchmarks to one CPU and count instructions per call
- Group constant validation context fields in a record
- Read the fail-fast flag in existing context matches
- Limit validator context lookups when changing scope
- Report allocated words per call in benchmarks
- Update the validator context only once when entering and leaving a $ref

### 🧪 Testing

- Cover fail-fast catches in 'contains', if and custom keywords

### ⚙️ Miscellaneous Tasks

- Make JSV.Validator.Error type non-opaque

## [0.26.2] - 2026-10-31

**Security fix: [CVE-2026-117680](https://cna.erlef.org/cves/CVE-2026-117680.html) / [GHSA-cvmg-hgv6-jqcp](https://github.com/lud/jsv/security/advisories/GHSA-cvmg-hgv6-jqcp).** All users validating untrusted data against schemas with `pattern` or `patternProperties` should upgrade.

When a regex exhausted its backtracking budget, the match was reported as a non-match. Data that matches a pattern only after heavy backtracking could then skip `patternProperties` subschemas, be validated by `additionalProperties` instead, or pass a `not: {pattern: ...}` deny-list.

An exhausted budget is now an indeterminate result: validation stops and returns a `JSV.ValidationError` with a single error of kind `indeterminate_pattern`, which combinators cannot invert. Such data is now always rejected, even when it would match. If valid data gets rejected this way, rewrite the pattern without nested quantifiers or overlapping alternatives.

`minLength` and `maxLength` now count Unicode code points instead of grapheme clusters, as required by the specification. For instance `"é"` written as `e` followed by U+0301 now has a length of 2.

### 🐛 Bug Fixes

- Count minLength and maxLength in code points (#151) – by Lars Hesel Christensen
- Fail validation when a regex exhausts its backtracking budget

### ⚡ Performance

- Keep a single cast stack per data level
- Zip array items with their schemas without streams (#153) – by Lars Hesel Christensen

### 🧪 Testing

- Updated JSON Schema test suite
- Run stderr capturing tests synchronously

## [0.26.1] - 2026-10-14

### 🚀 Features

- Strict RFC 3339 validation for date, time and date-time formats

### 🐛 Bug Fixes

- Reject comma as decimal separator in date-time format

## [0.26.0] - 2026-10-04

### 🚀 Features

- Expose error context data in normalized keyword errors

## [0.25.0] - 2026-09-25

### 🚀 Features

- Allow to configure current stacktrace for build warnings

## [0.24.0] - 2026-09-23

### 🚀 Features

- Warn on unresolved module atoms during schema normalization

### 🧪 Testing

- Updated JSON Schema Test Suite

## [0.23.1] - 2026-09-21

### 🐛 Bug Fixes

- Rename 'default' error level to 'cause'

## [0.23.0] - 2026-09-17

### 🚀 Features

- Allow hiding intermediary errors in error formatter

### 🐛 Bug Fixes

- Accept compressed IPv6 and embedded IPv4 hosts in uri and iri formats
- Fix propertyNames schemaLocation on errors

### 🧪 Testing

- Updated JSON Schema Test Suite

### ⚙️ Miscellaneous Tasks

- Limit justfile verbosity on mix.deps

## [0.22.0] - 2026-08-07

### 🚀 Features

- Implement uniqueItems for Decimal

### 🐛 Bug Fixes

- Raise explicit message on defschema without :properties

### 🚜 Refactor

- Extract test suite generation into JSV.TestSuiteGenerator

### 🧪 Testing

- Render floats as erlang would decode them when generating test suite
- Updated JSON Schema Test Suite
- Updated JSON Schema Test Suite and updated conformity tests

### ⚙️ Miscellaneous Tasks

- Document invalid JSON files in JSON Schema Test Suite

## [0.21.2] - 2026-07-10

### 🐛 Bug Fixes

- Ignore httpc cache chmod tests on windows
- Add missing type: object on arprops schema helper

### 📚 Documentation

- Added missing docs for public API

## [0.21.1] - 2026-07-06

### 🚀 Features

- Allow to define @doc above defschema to document json_schema/0 generated function

## [0.21.0] - 2026-07-05

### 🐛 Bug Fixes

- Prevent infinite recursion in cross ref schemas
- [**breaking**] JSV.Resolver.Httpc security defaults (no redirects, TLS verification, private atomic cache, size/timeout limits)
- Bound regex backtracking cost in pattern and patternProperties matching
- Support dynamicAnchor in id-less root schemas and fail gracefully on malformed keywords

### 📚 Documentation

- Document internal resolver security considerations

### 🧪 Testing

- Updated JSON Schema Test Suite
- Updated JSON Schema Test Suite

## [0.20.0] - 2026-06-26

### 🚀 Features

- Removed NimbleOptions dependency and changed internal options to use maps

### 🚜 Refactor

- Skip tracking casts and unevaluated paths when schemas do not need it

## [0.19.6] - 2026-06-25

### 🐛 Bug Fixes

- Support unicode general categories in pattern/patternProperties

### 🧪 Testing

- Updated JSON Schema Test Suite

## [0.19.5] - 2026-06-15

### 🐛 Bug Fixes

- Properly handle Draft-7 style anchor IDs

### 🧪 Testing

- Updated JSON Schema Test Suite

## [0.19.4] - 2026-06-07

### 🐛 Bug Fixes

- Fixed nested anchor resolution without root namespace

## [0.19.3] - 2026-05-30

### 🐛 Bug Fixes

- Allow module-based schemas in schema helpers typespecs

## [0.19.2] - 2026-05-29

### 🐛 Bug Fixes

- Make local resolver work on Windows (#95)
- Reject +/- prefixes on 'date' format

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema test suite
- Fix compilation warnings for Elixir 1.20

## [0.19.1] - 2026-05-13

### 🚀 Features

- Return better stacktraces in builder warnings

## [0.19.0] - 2026-05-10

### 🚀 Features

- [**breaking**] New cast system see https://hexdocs.pm/jsv/002-api-changes-v0-19.html (#90)
- [**breaking**] Converted schema presets to new cast system
- Added schema build warnings on atom casters (#91)
- Pass raw schema to casters at build time
- Added the aprops and arprops helpers to cast properties schemas to atom keys
- Removed the deprecated schema presets in JSV.Schema
- [**breaking**] Support Decimal 3.0 and drop support for Poison

### 🐛 Bug Fixes

- MultipleOf with Decimal support
- Ignore examples keyword when scanning schema
- Nullable() will now add nil to enums

### 📚 Documentation

- Document build_key usage with refs
- Reference drop of Poison support in migration guide

### ⚙️ Miscellaneous Tasks

- Added roadmap section to readme
- Refactor of the JSON Schema test suite generators
- Simplify built-in casts output syntax

## [0.18.3] - 2026-04-21

### 🐛 Bug Fixes

- Fixed schema scanning around non-schemas like properties
- Allow to dereference numeric pointers from maps in refs

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema Test Suite

## [0.18.2] - 2026-04-19

### 🐛 Bug Fixes

- Allow root $ref to resolve against root $id in Draft-7

### 📚 Documentation

- Fixed documentation for httpc resolver

### ⚙️ Miscellaneous Tasks

- Updated JSON Schema test suite

## [0.18.1] - 2026-04-08

### 🚀 Features

- Return a BuildError instead of raising a RuntimeError for :invalid_properties – by Bruce Williams

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
- Added the nullable/1 schema helper – by Jaden

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

