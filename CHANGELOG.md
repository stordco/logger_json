# Changelog

## [1.2.0](https://github.com/stordco/logger_json/compare/v1.1.3...v1.2.0) (2024-10-16)


### Features

* Support response body/headers logging on errors ([#20](https://github.com/stordco/logger_json/issues/20)) ([06095c9](https://github.com/stordco/logger_json/commit/06095c90c0c44a83557cfbb6276cd6a74b7ee45c))

## [1.1.3](https://github.com/stordco/logger_json/compare/v1.1.2...v1.1.3) (2024-02-07)


### Bug Fixes

* Don't scrub uploads ([#18](https://github.com/stordco/logger_json/issues/18)) ([1ebfaa4](https://github.com/stordco/logger_json/commit/1ebfaa441632e2f10a03766bf4996e82b3531664))

## [1.1.2](https://github.com/stordco/logger_json/compare/v1.1.1...v1.1.2) (2024-01-31)


### Bug Fixes

* Only regex a string ([#16](https://github.com/stordco/logger_json/issues/16)) ([b13b235](https://github.com/stordco/logger_json/commit/b13b235d1ad8d241b7c0772659e50ab49c57baf4))

## [1.1.1](https://github.com/stordco/logger_json/compare/v1.1.0...v1.1.1) (2023-11-19)


### Bug Fixes

* Scrub x-api-key ([#14](https://github.com/stordco/logger_json/issues/14)) ([36349bf](https://github.com/stordco/logger_json/commit/36349bf8325f5ab46380772c9ce348b679a023aa))

## [1.1.0](https://github.com/stordco/logger_json/compare/v1.0.4...v1.1.0) (2023-10-24)


### Features

* Default authorization header callback to support stord api keys ([#13](https://github.com/stordco/logger_json/issues/13)) ([43b29c7](https://github.com/stordco/logger_json/commit/43b29c7c5460821c7c7c0ecff597a989430a9773))
* Support additional scrubbing configuration and callbacks ([#11](https://github.com/stordco/logger_json/issues/11)) ([7a9ba85](https://github.com/stordco/logger_json/commit/7a9ba85732c28a8a5b9e936f4cf56767eeeb495f))

## [1.0.4](https://github.com/stordco/logger_json/compare/v1.0.3...v1.0.4) (2023-10-04)


### Bug Fixes

* Scrub cloud signature ([#10](https://github.com/stordco/logger_json/issues/10)) ([dbc00a9](https://github.com/stordco/logger_json/commit/dbc00a92111f95f0c8069eb00f15d3c97e40860b))


### Miscellaneous

* Sync files with stordco/common-config-elixir ([#7](https://github.com/stordco/logger_json/issues/7)) ([684b592](https://github.com/stordco/logger_json/commit/684b592f189f4ac75cf70c5874a20b36b27037a0))

## [1.0.3](https://github.com/stordco/logger_json/compare/v1.0.2...v1.0.3) (2023-08-08)


### Bug Fixes

* Add additional protective wrapping to crash log handling ([#5](https://github.com/stordco/logger_json/issues/5)) ([f7aba76](https://github.com/stordco/logger_json/commit/f7aba76f638a00b1a7c86448bf3f90b69b6eb56d))

## [1.0.2](https://github.com/stordco/logger_json/compare/v1.0.1...v1.0.2) (2023-08-01)


### Bug Fixes

* Scrub nested body key values ([83d2855](https://github.com/stordco/logger_json/commit/83d2855c5663363d3eff5f85d94ef130d2d56fcc))
* Scrub tuple values ([e680ed7](https://github.com/stordco/logger_json/commit/e680ed7c389f547bb904e5419c64cbe9fe31c84e))


### Miscellaneous

* Fix warning during compile ([0a90846](https://github.com/stordco/logger_json/commit/0a908465a2d151de39389995888d5dd38a894846))
* Update credo ignore rule ([8893e30](https://github.com/stordco/logger_json/commit/8893e30a215067b5ddfe79490ba60cfd4a94c8bc))

## [1.0.1](https://github.com/stordco/logger_json/compare/v1.0.0...v1.0.1) (2023-07-31)


### Bug Fixes

* Update datadog plug formatter for tuples and maps ([0b238d4](https://github.com/stordco/logger_json/commit/0b238d4ea850cf6d9e22158451182df42bc54e79))

## 1.0.0 (2023-07-31)


### Features

* Add datadog error tracking attributes ([05c3bc3](https://github.com/stordco/logger_json/commit/05c3bc3f9261ae55043d61dfece1d9c4f9a733c2))
* Add phoenix route to plug metadata ([#90](https://github.com/stordco/logger_json/issues/90)) ([b4b9b9e](https://github.com/stordco/logger_json/commit/b4b9b9eb783d44298fa6445fa9a889c26cfd8788))
* Add request headers and params to logger body ([893e4dc](https://github.com/stordco/logger_json/commit/893e4dc279bf1ca71220acad84459fe86eaaf85a))
* Allow converting otel trace ids to datadog values ([#91](https://github.com/stordco/logger_json/issues/91)) ([d13b725](https://github.com/stordco/logger_json/commit/d13b725b5bc905e243e1c8781a2c80e91906aaf2))
* Allow setting Datadog syslog.hostname attribute ([#87](https://github.com/stordco/logger_json/issues/87)) ([cad53fe](https://github.com/stordco/logger_json/commit/cad53feaadddaa1766a7fde33b504f3b1da3cd13))
* Use Datadog error tracking fields for crashes ([e7a6efa](https://github.com/stordco/logger_json/commit/e7a6efa4892f9c75ff415c260b2db96245e1203a))


### Bug Fixes

* Safely format values within tuples ([#74](https://github.com/stordco/logger_json/issues/74)) ([b5b4f22](https://github.com/stordco/logger_json/commit/b5b4f224bf295252c8989bd22b0551c155c2ee93))


### Miscellaneous

* Add note to README ([45c4a82](https://github.com/stordco/logger_json/commit/45c4a8204a1123ad09a23f06c0c16d6fd413ed57))
* Add tool versions file ([9032fa2](https://github.com/stordco/logger_json/commit/9032fa20442b714e1a9bad5893d7381ab995d2ec))
* Remove typo ([#100](https://github.com/stordco/logger_json/issues/100)) ([987aabc](https://github.com/stordco/logger_json/commit/987aabc835c6b37555aa62a6a76b6cac65ceed93))
* Remove unused deps from mix lock file ([d16d6ed](https://github.com/stordco/logger_json/commit/d16d6edc112e81dbb8e04e2c6fc824128517abe2))
* Sync files with stordco/common-config-elixir ([#2](https://github.com/stordco/logger_json/issues/2)) ([be7a775](https://github.com/stordco/logger_json/commit/be7a775fe098e51f09a5c2b046b9afc77d019aaf))
* Time unit ([#18](https://github.com/stordco/logger_json/issues/18)) ([f620d15](https://github.com/stordco/logger_json/commit/f620d1560df264f64548cbe9d35ff5656f0c914d))
* Update to stord spec elixir repository ([21d0f42](https://github.com/stordco/logger_json/commit/21d0f4279ada1166a60771f196514cd454cd3ec9))
