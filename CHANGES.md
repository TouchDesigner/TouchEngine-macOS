# Changes

## 3.3

* Add TEInstanceLinkGetChoices(), deprecate TEInstanceLinkHasChoices(), TEInstanceLinkGetChoiceLabels(), TEInstanceLinkGetChoiceValues()
* Fix issue which could cause texture transfers to be unavailable in some circumstances
* Fix issue which could cause duplicated callbacks when some outputs changed

## 3.2

* Fix issue which could cause unexpected behaviour in OpenGL hosts after a texture output was resized
* Fix issue which prevented users launching TouchDesigner while TouchEngine was in use on macOS (requires TouchDesigner 2023.11629 or later)

## 3.1

* Add TEInstanceSetPreferredEnginePath(), TEInstanceGetPreferredEnginePath() and TEInstanceGetConfiguredEnginePath()
* Fix issue which prevented GPU selection working for Vulkan hosts in some circumstances
* Fix issue which caused TEInstanceGetSupportedTextureTypes() to return bad values for some older TouchDesigner versions
* When TouchDesigner 2023.11600 is in use on a user's system, output textures will always be IOSurface-backed to avoid a bug with Metal texture output in that version

## 3.0

* Add TELinkTypeSequence and TEInstanceLinkSetSequenceCount()
	Sequences are repeating groups of parameters. The number of repetitions is user configurable.

## 2.7

* Add TEInstanceLinkHasValue() and TELinkValueUIMinimum, TELinkValueUIMaximum
* Add support for some more sRGB compressed texture formats
* Fix issue which could prevent TEObjectEventEndUse being sent in some circumstances
* Fix issue which prevented linking when using Xcode 15

## 2.6

* Fix an issue which could cause unexpected behaviour for texture inputs or outputs following a crash in the TouchEngine process

## 2.5

* Add TEOpenGLContextSupportsTexturesForInstance()
* Improve error reporting in cases where the TouchEngine process crashes

## 2.4

* Add TEInstanceSetAssetDirectory() and TEInstanceGetAssetDirectory()
* Fix crash which could occur handling component errors during loading

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
