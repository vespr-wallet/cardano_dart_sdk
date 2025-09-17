# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VESPR Wallet is a multi-platform cryptocurrency wallet application built with Flutter, supporting iOS, Android, and Chrome/Brave web extensions. It integrates with the Cardano blockchain and supports hardware wallets (Ledger, Keystone).

## Essential Commands

### Build Commands

```bash
# Generate squadron workers dart code
dart run build_runner build --delete-conflicting-outputs

# Generates the web workers from squadron dart workers
sh ./scripts/gen_js_workers.sh

```

### Development Commands

```bash
# Format code in current module's lib directory (excluding generated files)
dart format $(find lib -name "*.dart" -not \( -name "*.*freezed.dart" -o -name "*.*g.dart" -o -name "*.gr.dart" \) ) --line-length=120

# Run tests
flutter test
```

## Architecture

### Build Process Flow

1. dart run build_runner build --delete-conflicting-outputs
2. sh ./scripts/gen_js_workers.sh

### Coding Standards

- **Line length**: 120 characters
- **Trailing commas**: Always preserve for better formatting
- **Error handling**: Use try-catch blocks and fail fast
- **Enums**: Use switch statements without default case to ensure all cases are handled
- **Sealed classes**: Strongly prefer sealed classes for deterministic states (UI loading/data/error states, etc.) with exhaustive switch statements (no default case)
- **Type casting**: Avoid force-casting. Use smart casting instead. Create local variables from class fields when needed to enable smart casting
- **Immutability**: Use `final` for everything by default. Mutable variables/fields should be avoided unless required for specific algorithms
- **Code readability**: Write code that follows a clear, easy-to-understand flow. Prioritize readability over cleverness
- **Named arguments**: Always use required named arguments, even when nullable. Avoid optional parameters unless they're truly optional configuration
- **Mutually exclusive arguments**: Never use nullable arguments as shortcuts for mutually exclusive options. Use sealed union classes with exhaustive switch statements instead

### CI/CD

**GitHub Actions:**

- **Mobile Tests** (`/.github/workflows/mobile-tests.yml`): Automatically runs unit tests on pull requests to develop/main branches
  - Triggers on changes to lib/, test/, core/, critical/, modules/ directories
  - Flutter version is managed via `.tool-versions` file (ASDF)
  - Includes dependency caching for faster builds
  - Runs code analysis and tests with coverage reporting

## Linear

**Team Info:**

- The linear team is `56655caa-1ccb-4ed1-aeb1-956e6d11bf1d`. Don't try to fetch it from MCP.

## CIPs (Cardano Improvement Proposals)

When working with features that reference CIPs, you must read the official documentation:

### Finding CIP Documentation

1. **For merged CIPs**: Access documentation from the Cardano Foundation GitHub repository

   - Pattern: `https://raw.githubusercontent.com/cardano-foundation/CIPs/refs/heads/master/CIP-{NUMBER}/README.md`
   - Example: CIP-13 (Cardano URI Scheme): https://raw.githubusercontent.com/cardano-foundation/CIPs/refs/heads/master/CIP-0013/README.md

2. **For draft CIPs**: These are not yet merged to master
   - Check open pull requests in the CIPs repository
   - Ask for the specific PR URL if the CIP cannot be found in master
   - **IMPORTANT**: Do NOT proceed without reading the documentation. Always request the correct URL if a CIP is not found.

### Working with CIPs

- The app frequently implements support for various CIPs
- Always verify you're reading the correct version (merged vs draft)
- When implementing CIP-related features, reference the CIP number in code comments and git commit
