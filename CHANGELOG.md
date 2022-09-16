# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0](https://github.com/voxpupuli/beaker-google/tree/0.4.0) (2022-09-15)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.3.0...0.4.0)

**Implemented enhancements:**

- Migrated from the deprecated `google-api-client` to the more modern `google-apis-compute`

**Breaking changes:**

- Removed the mysterious `kill_zombies()` method since it was more of a helper and could result in potentially
  unexpected results
  - Users will now need to clean up artifacts from unexpected job termination manually instead of including this method
    into their test code
