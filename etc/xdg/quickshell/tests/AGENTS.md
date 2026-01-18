# Quickshell Testing Framework

## Overview
Custom Mock-Wrapper-Runner framework for testing Quickshell components without a running Wayland compositor. Uses a SimpleTest DSL to verify UI states and system integrations.

## Architecture
```
tests/
├── run.sh              # Orchestrator: setup -> execute -> cleanup
├── setup_wrappers.sh   # Rewrites components to remove WlrLayershell dependencies
├── framework/          # SimpleTest.qml DSL (compare, verify, wait)
├── mocks/              # Quickshell system mocks (Services, Io, Wayland)
├── wrappers/           # Modified source components (auto-generated)
└── tst_*.qml           # Test suites
```

## Workflow
1. **Setup**: `./tests/run.sh` calls `setup_wrappers.sh`.
2. **Transform**: Source files are copied to `wrappers/` with `WlrLayershell` stripped to allow head-less/windowed execution.
3. **Mocking**: `qmldir` in `mocks/` redirects `Quickshell` imports to local mock implementations.
4. **Execution**: Each `tst_*.qml` is run via `quickshell`.
5. **DSL**: Tests use `SimpleTest` for assertions and async event waiting.

## Commands
```bash
# Run all tests
./tests/run.sh

# Run specific suite
./tests/run.sh tests/tst_Status.qml

# Update wrappers only
./tests/setup_wrappers.sh
```

## Writing Tests
- **Imports**: Import from `wrappers/` instead of `components/`.
- **Mocks**: Global mocks are automatically provided via `QML_IMPORT_PATH` in `run.sh`.
- **DSL Example**:
  ```qml
  SimpleTest {
      function test_toggle() {
          compare(component.visible, false)
          component.toggle()
          verify(component.visible)
      }
  }
  ```

## Key Directories
| Path | Purpose |
|------|---------|
| `mocks/Quickshell/` | Mocks for DBus, Pipewire, UPower, and Wayland types |
| `wrappers/` | Strip-down versions of `components/` for testing |
| `framework/` | Core testing logic and assertion helpers |
