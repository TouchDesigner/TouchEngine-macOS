# Changes

## 2.3

* Add TEInstanceLinkHasUserTint() and TEInstanceLinkGetUserTint()
* Add detailed reporting for component errors via TEInstanceGetErrors()
* A subsequent call to TEInstanceConfigure() before a previous configuration has completed now completes the initial configuration with TEResultCancelled
* Check for presence of TOUCHENGINE_APP_PATH environment variable to specificy a TouchDesigner installation to use
* Fix an issue which could cause lost CHOP or DAT values when running in independent mode
* Fix an issue which could leave a TEInstance in an inconsistent state if the TouchEngine process crashed
* Fix an issue which could cause a crash releasing a TETable or TEFloatData
* Other fixes for stability

## 2.0

* Initial macOS public release
