# Changelog

## [1.2.0](https://github.com/voxpupuli/beaker-google/tree/1.2.0) (2026-11-03)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/1.2.0...1.2.0)

**Fixed bugs:**

- Let a non-empty BEAKER\_gce\_ports replace configured gce\_ports [\#74](https://github.com/voxpupuli/beaker-google/pull/74) ([jaevans](https://github.com/jaevans))

**Closed issues:**

- Compute calls fail with "Invalid API version '2026-11-01'" since google-apis-compute\_v1 0.157.0 [\#76](https://github.com/voxpupuli/beaker-google/issues/76)

**Merged pull requests:**

- Pin the Compute API version sent to Compute Engine [\#77](https://github.com/voxpupuli/beaker-google/pull/77) ([michael-riddle](https://github.com/michael-riddle))
- Remove CodeQL workflow in favor of default setup [\#75](https://github.com/voxpupuli/beaker-google/pull/75) ([jaevans](https://github.com/jaevans))
- Bump actions/checkout from 6 to 7 [\#71](https://github.com/voxpupuli/beaker-google/pull/71) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump rubygems/configure-rubygems-credentials from 1.0.0 to 2.1.0 [\#70](https://github.com/voxpupuli/beaker-google/pull/70) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/download-artifact from 7 to 8 [\#68](https://github.com/voxpupuli/beaker-google/pull/68) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/upload-artifact from 6 to 7 [\#67](https://github.com/voxpupuli/beaker-google/pull/67) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/upload-artifact from 5 to 6 [\#66](https://github.com/voxpupuli/beaker-google/pull/66) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/download-artifact from 6 to 7 [\#65](https://github.com/voxpupuli/beaker-google/pull/65) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/checkout from 5 to 6 [\#64](https://github.com/voxpupuli/beaker-google/pull/64) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/upload-artifact from 4 to 5 [\#63](https://github.com/voxpupuli/beaker-google/pull/63) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/download-artifact from 5 to 6 [\#62](https://github.com/voxpupuli/beaker-google/pull/62) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump github/codeql-action from 3 to 4 [\#61](https://github.com/voxpupuli/beaker-google/pull/61) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump actions/checkout from 4 to 5 [\#60](https://github.com/voxpupuli/beaker-google/pull/60) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update thin requirement from ~\> 1.8, \>= 1.8.2 to \>= 1.8.2, \< 3 [\#59](https://github.com/voxpupuli/beaker-google/pull/59) ([dependabot[bot]](https://github.com/apps/dependabot))
- Add rspec tests [\#57](https://github.com/voxpupuli/beaker-google/pull/57) ([silug](https://github.com/silug))
- Update voxpupuli-rubocop requirement from ~\> 2.8.0 to ~\> 3.1.0 [\#56](https://github.com/voxpupuli/beaker-google/pull/56) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update voxpupuli-rubocop requirement from ~\> 2.7.0 to ~\> 2.8.0 [\#55](https://github.com/voxpupuli/beaker-google/pull/55) ([dependabot[bot]](https://github.com/apps/dependabot))

## [1.2.0](https://github.com/voxpupuli/beaker-google/tree/1.2.0) (2024-06-07)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/1.1.0...1.2.0)

**Implemented enhancements:**

- CI: Run on Ruby 3.2 and 3.3 as well [\#52](https://github.com/voxpupuli/beaker-google/pull/52) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- Fix call to Google::Apis::ComputeV1::Instance.new\(\) to work on Ruby 3 [\#51](https://github.com/voxpupuli/beaker-google/pull/51) ([silug](https://github.com/silug))

**Merged pull requests:**

- CI: build gem with --strict & --verbose [\#53](https://github.com/voxpupuli/beaker-google/pull/53) ([bastelfreak](https://github.com/bastelfreak))
- Cleanup for rubocop [\#50](https://github.com/voxpupuli/beaker-google/pull/50) ([silug](https://github.com/silug))

## [1.1.0](https://github.com/voxpupuli/beaker-google/tree/1.1.0) (2024-05-22)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/1.0.0...1.1.0)

**Implemented enhancements:**

- Move timestamp in firewall name to a different value [\#45](https://github.com/voxpupuli/beaker-google/issues/45)
- Add ability to configure the firewall [\#40](https://github.com/voxpupuli/beaker-google/pull/40) ([jaevans](https://github.com/jaevans))
- Add ability to set custom hostname [\#39](https://github.com/voxpupuli/beaker-google/pull/39) ([Andy-Adrian](https://github.com/Andy-Adrian))

**Closed issues:**

- Add ability to set custom hostname [\#38](https://github.com/voxpupuli/beaker-google/issues/38)
- network ports should be configurable [\#34](https://github.com/voxpupuli/beaker-google/issues/34)

**Merged pull requests:**

- Fix name conflicts [\#48](https://github.com/voxpupuli/beaker-google/pull/48) ([jaevans](https://github.com/jaevans))
- Bump actions/checkout from 2 to 4 [\#43](https://github.com/voxpupuli/beaker-google/pull/43) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump github/codeql-action from 1 to 2 [\#42](https://github.com/voxpupuli/beaker-google/pull/42) ([dependabot[bot]](https://github.com/apps/dependabot))
- dependabot: check for github actions and bundler [\#41](https://github.com/voxpupuli/beaker-google/pull/41) ([bastelfreak](https://github.com/bastelfreak))
- Update fakefs requirement from ~\> 1.8 to ~\> 2.4 [\#37](https://github.com/voxpupuli/beaker-google/pull/37) ([dependabot[bot]](https://github.com/apps/dependabot))

## [1.0.0](https://github.com/voxpupuli/beaker-google/tree/1.0.0) (2022-11-02)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.5.0...1.0.0)

**Fixed bugs:**

- exec sysprep commands in child processes [\#31](https://github.com/voxpupuli/beaker-google/pull/31) ([Andy-Adrian](https://github.com/Andy-Adrian))

## [0.5.0](https://github.com/voxpupuli/beaker-google/tree/0.5.0) (2022-10-04)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.4.0...0.5.0)

**Implemented enhancements:**

- Also enable SSH on images from the windows-sql-cloud project [\#27](https://github.com/voxpupuli/beaker-google/pull/27) ([jaevans](https://github.com/jaevans))
- Add the OpenSSH directory to the system path [\#25](https://github.com/voxpupuli/beaker-google/pull/25) ([jaevans](https://github.com/jaevans))
- Enable windows support [\#23](https://github.com/voxpupuli/beaker-google/pull/23) ([jaevans](https://github.com/jaevans))

## [0.4.0](https://github.com/voxpupuli/beaker-google/tree/0.4.0) (2022-09-16)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.3.0...0.4.0)

**Merged pull requests:**

- Update rake requirement from ~\> 10.1 to ~\> 13.0 [\#20](https://github.com/voxpupuli/beaker-google/pull/20) ([dependabot[bot]](https://github.com/apps/dependabot))
- Transfer to Vox Pupuli Prep [\#19](https://github.com/voxpupuli/beaker-google/pull/19) ([yachub](https://github.com/yachub))
- Support updated google APIs [\#17](https://github.com/voxpupuli/beaker-google/pull/17) ([jaevans](https://github.com/jaevans))
- Update fakefs requirement from ~\> 0.6 to ~\> 1.8 [\#16](https://github.com/voxpupuli/beaker-google/pull/16) ([dependabot[bot]](https://github.com/apps/dependabot))

## [0.3.0](https://github.com/voxpupuli/beaker-google/tree/0.3.0) (2022-09-08)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.2.1...0.3.0)

**Merged pull requests:**

- \(RE-14811\) Add RE as codeowners [\#18](https://github.com/voxpupuli/beaker-google/pull/18) ([yachub](https://github.com/yachub))
- \(DIO-3133\) Scan repo with Snyk [\#13](https://github.com/voxpupuli/beaker-google/pull/13) ([suckatrash](https://github.com/suckatrash))
- Add Dependabot to keep thins up to date [\#8](https://github.com/voxpupuli/beaker-google/pull/8) ([genebean](https://github.com/genebean))

## [0.2.1](https://github.com/voxpupuli/beaker-google/tree/0.2.1) (2020-01-29)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.2.0...0.2.1)

**Merged pull requests:**

- \(MAINT\) update beaker testing version [\#7](https://github.com/voxpupuli/beaker-google/pull/7) ([kevpl](https://github.com/kevpl))
- \(MAINT\) remove markdown requirement [\#6](https://github.com/voxpupuli/beaker-google/pull/6) ([kevpl](https://github.com/kevpl))
- Update google-api-client dependency [\#5](https://github.com/voxpupuli/beaker-google/pull/5) ([cdenneen](https://github.com/cdenneen))

## [0.2.0](https://github.com/voxpupuli/beaker-google/tree/0.2.0) (2018-09-17)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/0.1.0...0.2.0)

**Merged pull requests:**

- \(BKR-1509\) Hypervisor usage instructions for Beaker 4..0 [\#4](https://github.com/voxpupuli/beaker-google/pull/4) ([Dakta](https://github.com/Dakta))
- \(MAINT\) Overall GCE Updates [\#3](https://github.com/voxpupuli/beaker-google/pull/3) ([trevor-vaughan](https://github.com/trevor-vaughan))

## [0.1.0](https://github.com/voxpupuli/beaker-google/tree/0.1.0) (2017-07-19)

[Full Changelog](https://github.com/voxpupuli/beaker-google/compare/34ca3d6b58dd87455316e055214367215fdff71f...0.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
