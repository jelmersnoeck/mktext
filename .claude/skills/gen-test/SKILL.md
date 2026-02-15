---
name: gen-test
description: Generate XCTest unit tests following existing test patterns in mktextTests/
disable-model-invocation: true
---

Generate XCTest unit tests for the specified Swift source file or module.

## Process

1. Read the target source file to understand what needs testing
2. Read `mktextTests/MarkdownParserTests.swift` to match existing test patterns and style
3. Generate test cases covering:
   - Normal/expected inputs
   - Edge cases and boundary conditions
   - Error conditions
4. Add tests to the appropriate test file in `mktextTests/`, or create a new test file if none exists for the module
5. Run `swift test` to verify all tests pass

## Test file naming convention

- Test files go in `mktextTests/`
- Name: `{SourceFileName}Tests.swift`
- Class: `{SourceFileName}Tests: XCTestCase`

## Style guidelines

- Follow the XCTest patterns already in the project
- Use descriptive test method names: `test{Behavior}_{Condition}_{ExpectedResult}`
- Keep each test focused on one behavior
- Use XCTAssertEqual for value comparisons, XCTAssertTrue/False for booleans
