# Changelog

## [1.1.0](https://github.com/Shir0o/auto-vol/compare/v1.0.0...v1.1.0) (2026-10-06)


### Features

* add git pre-commit hook for auto-formatting Dart files ([88acec9](https://github.com/Shir0o/auto-vol/commit/88acec99cecb5062bc08dd31816d8ec407f8c21a))
* add multi-calendar support, skeleton loaders, and pull-to-refresh ([95a8526](https://github.com/Shir0o/auto-vol/commit/95a85266e735c77cb0a9da36c8f967b906007029))
* add preference to include/exclude all-day events ([33f30cb](https://github.com/Shir0o/auto-vol/commit/33f30cbda151b186d27c3adb6c8ac5a286534ac0))
* centralize volume automation by moving event tuning to rules screen ([e64cca4](https://github.com/Shir0o/auto-vol/commit/e64cca48f8826b14e213589ba1eb9c8767091dba))
* configure Google Sign-In with Android and iOS Client IDs ([08c62ce](https://github.com/Shir0o/auto-vol/commit/08c62ced0c185503b929499ee0ce41682f0cda67))
* enhance automation transparency and schedule screen UX ([c208163](https://github.com/Shir0o/auto-vol/commit/c2081639f04df42c4708b6edb5fc7b263e10a9d3))
* enhance automation with heartbeat, volume restore, and calendar refresh ([#2](https://github.com/Shir0o/auto-vol/issues/2)) ([b4b515d](https://github.com/Shir0o/auto-vol/commit/b4b515d65b10538c287e7769852da2264489308c))
* enhance schedule UI with calendar attribution and local time display ([6f9cfdc](https://github.com/Shir0o/auto-vol/commit/6f9cfdc1027d07d221437ae66cabd5f2529ff38a))
* implement Android Foreground Service for background automation ([4ac2170](https://github.com/Shir0o/auto-vol/commit/4ac2170e198cb128fa668b7bc9f8a8c12d857508))
* implement Aura app core automation and UI with TDD ([a3813bb](https://github.com/Shir0o/auto-vol/commit/a3813bb4f00f6f63b01d7eca74ffda6cdf558895))
* implement functional Google Sign-In with status UI in Settings ([112cb3c](https://github.com/Shir0o/auto-vol/commit/112cb3cfc2b0f877fb825f40d4dd5e4a4e95c66d))
* implement initial permission requests on app startup ([112a723](https://github.com/Shir0o/auto-vol/commit/112a72346856b829f7005904aed81007bc9e00c8))
* implement manual overrides, permission prompts, and conflict UI ([73f5e78](https://github.com/Shir0o/auto-vol/commit/73f5e7830dd5ac0b5427955d6355da70b752860f))
* implement robust silent sign-in and auth state management ([94e8e6f](https://github.com/Shir0o/auto-vol/commit/94e8e6f1e254ae89a9dada37ed4653f2f0766bfe))
* implement TDD-backed onboarding flow and permission handling ([37982a3](https://github.com/Shir0o/auto-vol/commit/37982a3c6d4ac80ab9313ccb466275e29dd4dd75))
* implement Volume Rule Management UI ([49321c0](https://github.com/Shir0o/auto-vol/commit/49321c04f61de70d07264d0aa1f7268abb7aec5e))
* improve automation transparency and rules guidance ([191fa86](https://github.com/Shir0o/auto-vol/commit/191fa86f9fc70f2320e28acb951ea276356c833f))
* move google client ids to .env and improve startup loading experience ([88edb9b](https://github.com/Shir0o/auto-vol/commit/88edb9b3c049190e2d0be9c7ab877f7dc2f1a950))
* redesign schedule view to Google Calendar style with day headers ([00ce9a0](https://github.com/Shir0o/auto-vol/commit/00ce9a0cf46da667c6883e33e5e0c16150fc6ade))
* remove calendar name from schedule page and clean up outdated tests ([65e5372](https://github.com/Shir0o/auto-vol/commit/65e5372a26731e2775dac9313ff02e63ec73e544))
* remove Sync Status page and make Schedule the home page ([8e1d0da](https://github.com/Shir0o/auto-vol/commit/8e1d0daa4ca3433d4a7a2d55903c0a30f3cf8f96))
* remove unused location permissions and logic ([9e34d96](https://github.com/Shir0o/auto-vol/commit/9e34d96ea3f71ab74098810225386f7086f742de))
* remove VIPs feature ([46574ec](https://github.com/Shir0o/auto-vol/commit/46574eccd202c4eac98f61ff7c7fe3f8c8093fc1))
* **ui:** improve schedule skeleton loaders and update page title ([bc198eb](https://github.com/Shir0o/auto-vol/commit/bc198eb119037d4d3d1f44b5b10eb374a610d076))


### Bug Fixes

* add missing REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission and update .gitignore ([05cbae0](https://github.com/Shir0o/auto-vol/commit/05cbae0d0f9b9b7e298f7b7e2780ca2d8e2f24cf))
* **ci:** format Play Store release notes without leading spaces or excess blank lines ([#14](https://github.com/Shir0o/auto-vol/issues/14)) ([4e80f9f](https://github.com/Shir0o/auto-vol/commit/4e80f9f5696fc1f2cfa8de7b0af18233eb396ddf))
* prevent foreground service from enforcing default volume when inactive ([7f263eb](https://github.com/Shir0o/auto-vol/commit/7f263eb35542ca74fee5afdc34174238ef65ad3b))
* remove invalid scopes parameter and fix syntax error in main.dart ([6cc7b48](https://github.com/Shir0o/auto-vol/commit/6cc7b489146096eea46ba77ae28174f148481391))
* request scopes upfront and use persistent auth state to prevent multiple dialogues ([f0e3a9e](https://github.com/Shir0o/auto-vol/commit/f0e3a9e60f3f424342d6a1aea9c4ce90a5d76e81))
* resolve compilation errors in auth service and common providers ([9889c6f](https://github.com/Shir0o/auto-vol/commit/9889c6f28aaffaff33bdc193b8a8bcd6b1f66ecd))
* use web client id for android google sign-in to resolve error 28444 ([b71a77c](https://github.com/Shir0o/auto-vol/commit/b71a77cc4318c8319450bc8c39a36f2bd45d0086))


### Refactoring

* rename project to Vocus and update package name to com.shir0o.vocus ([d13d421](https://github.com/Shir0o/auto-vol/commit/d13d42152f719cb0633cf1d39c5305df09d45e35))
* rename project to Volo and update package name to com.shir0o.volo ([e314611](https://github.com/Shir0o/auto-vol/commit/e3146117f0f6c13a1de775f490b454f1cd7b8e2d))
