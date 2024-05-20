TouchEngine
===========

TouchEngine provides an API to load and render TouchDesigner components.

SDK
---

This repository contains TouchEngine.framework which is the framework you will use in your own applications, as well as an example project. The SDK for Windows is available at https://github.com/TouchDesigner/TouchEngine-Windows.

Instances And TouchDesigner Installations
-----------------------------------------

TouchEngine requires an installed version of TouchDesigner to load and work with components, along with any paid license (TouchPlayer/TouchDesigner Pro/Commercial/Educational). TouchEngine will locate an installed version suitable for use on the user's system. TouchEngine will return errors for missing or unlicensed installations, which you should communicate to the user.

The earliest TouchDesigner version which works with this version of TouchEngine is 2020.28110. Generally, the most up-to-date release is recommended.

By default the most recent version of TouchDesigner will be used. If necessary, you can select a particular installation with `TEInstanceSetPreferredEnginePath()`.

Users can specify a particular version to use by including a folder named "TouchEngine" alongside the component .tox being loaded. This folder can be a renamed TouchDesigner installation directory, or a file-system link to an installation (either a symbolic link or a macOS Finder alias). Alternatively an environment variable `TOUCHENGINE_APP_PATH` can be set to the path to a TouchDesigner application. Either of these user-indicated selections will override the effects of `TEInstanceSetPreferredEnginePath()`.


Example Project
---------------

The example project "Hello TouchEngine" demonstrates some of the techniques discussed below. The classes prefixed "TCH" may be useful in your own projects to manage resources shared with TouchEngine, and to correctly handle some of the considerations detailed below.


API Documentation
-----------------

The TouchEngine API is documented in the TouchEngine headers. This document gives a high-level overview and details some best practices for working with the API.


Using TouchEngine
-----------------

In Xcode, add TouchEngine.framework to the "Frameworks, Libraries, and Embedded Content" section for your target in the "General" tab for your application's target. Select "Embed and Sign" in the "Embed" menu. `#include <TouchEngine/TouchEngine.h>` in any source file you wish to use TouchEngine in. Note that to graphics-specific functions are not included in the umbrella header. For example to use Metal, add `#include <TouchEngine/TEMetal.h>` to your includes.


TEObjects
---------

Objects created or returned from the TouchEngine API are reference-counted, and you take ownership of objects returned to you from the API. If you use an API function with "Create" or "Get" in its name which returns a TEObject (including via a function argument), you must use `TERelease()` when you are finished with the object.

    TELinkInfo *info;
    TEResult result = TEInstanceLinkGetInfo(instance, identifier, &info);
    if (result == TEResultSuccess)
    {
        // You become the owner of the TELinkInfo object
        // use the object...
        // ...
        // ...and then release it
        TERelease(&info);
        // (info is set to NULL by TERelease()) 
    }

You can use `TERetain()` to increase the reference-count of an object.

Some functions accept or return several types of TEObject. Use `TEGetType()` to check the type of a TEObject returned from such functions, then cast the value to the actual type.

For C++ code, you may wish to use the `TouchObject` class in TouchEngine/TouchObject.h, which wraps TEObjects and takes care of retain and release. See TouchObject.h for documentation.


Links
-----

Individual inputs and outputs of an instance are referred to as *links*. In TouchDesigner terms, links combine parameters and In and Out operators.


Creating and Configuring Instances
----------------------------------

An instance requires two callbacks: one for instance events, and one to receive link events:

    void eventCallback(TEInstance * instance, TEEvent event, TEResult result, int64_t start_time_value, int32_t start_time_scale, int64_t end_time_value, int32_t end_time_scale, void * info)
    {
        // handle the event
    }
    
    void linkCallback(TEInstance * instance, TELinkEvent event, const char *identifier, void * info)
    {
        // handle the link event
    }

A single instance can be re-used to load several components. Only one component can be loaded in an instance at a time (but any number of instances can co-exist). Improve performance by re-configuring an existing instance rather than creating a new one where possible.

Create an instance:

    TEInstance *instance;
    TEResult result = TEInstanceCreate(eventCallback, linkCallback, NULL, &instance);
    if (result == TEResultSuccess)
    {
        // Continue to use the instance
    }

If working with textures, create and associate a TEGraphicsContext suitable for your needs. A graphics context directs TouchEngine to use a specific graphics device, and provides functionality to work with textures using your chosen graphics API. Alternatively you can create and associate a TEAdapter to indicate a device without the full functionality of a graphics context. If neither are associated, the instance will select a device as it sees fit.

    // See TEGraphicsContext.h to create a suitable context
    if (result == TEResultSuccess)
    {
        result = TEInstanceAssociateGraphicsContext(instance, context);
    }

You may wish to set a frame-rate to match your intended render rate:

    if (result == TEResultSuccess)
    {
        // for example, this would set 30 FPS
        result = TEInstanceSetFrameRate(instance, 30, 1);
    }

Configure and load a component:

    if (result == TEResultSuccess)
    {
        result = TEInstanceConfigure(instance, "sample.tox", TETimeExternal);
    }
    if (result == TEResultSuccess)
    {
        result = TEInstanceLoad(instance);
    }

Loading begins immediately.

During loading you will receive link callbacks with the event TELinkEventAdded for any links on the instance.

Once loading has completed you will receive an event callback with the event `TEEventInstanceDidLoad`, and a TEResult indicating success or any warning or error.

An instance is loaded suspended. Once configured, resuming the instance will permit rendering (and start playback in TETimeInternal mode):

    if (result == TEResultSuccess)
    {
        result = TEInstanceResume(instance);
    }

Note that if you are able to call `TEInstanceConfigure()` with a NULL path sometime before loading a component, the instance will perform some pre-loading setup. You can then call `TEInstanceConfigure()` again with a valid path, and the subsequent `TEInstanceLoad()` will complete much faster.


Rendering An Instance
---------------------

Rendering is performed asynchronously according to the TETimeMode of the instance.

For a TETimeExternal instance, rendering is driven by your API calls. Times passed to `TEInstanceStartFrameAtTime()` determine progress.

For a TETimeInternal instance, rendering continues in the background at the instance's frame-rate. Output is driven by calls to `TEInstanceStartFrameAtTime()`.

For both modes, after starting a frame the instance's link callback will be invoked for outputs whose value has changed. The completion of a frame you have requested is marked by the event callback receiving TEEventFrameDidFinish with a TEResult indicating success or any warning or error.


Working With TELinkTypeFloatBuffer
----------------------------------

Float buffer links take or emit a buffer of float values arranged in channels. They can contain time-based or static values. One example of time-based values is audio data. An example of static values might be coordinates, perhaps with a channel for each dimension.

To allow the most efficient memory re-use inside TouchEngine, for each input link create a TEFloatBuffer once (using `TEFloatBufferCreate()` or `TEFloatBufferCreateTimeDependent()`) and then create subsequent buffers from the original buffer using `TEFloatBufferCreateCopy()`.

Time-dependent buffers can be added to the instance with `TEInstanceLinkAddFloatBuffer()`, which adds the buffer to an internal queue.

For static values, calling `TEInstanceLinkSetFloatBufferValue()` replaces any current value as well as clearing any time-dependent values previously queued.

To receive time-dependent buffers from the instance, call `TEInstanceLinkGetFloatBufferValue()` from your `TEInstanceLinkCallback`. No further buffers will be received during the callback, allowing you to safely dequeue them without risk of loss.


Working with TELinkTypeStringData
---------------------------------

String data links can be tables or a single string value.

When working with table inputs, to allow the most efficient memory re-use inside TouchEngine, for each link create a TETable once using `TETableCreate()` and then create subsequent tables from the original table using `TETableCreateCopy()`.

Set a single string value on a string data input with `TEInstanceLinkSetStringValue()`, or set a table value with `TEInstanceLinkSetTableValue()`. To receive string data values from an output, use `TEInstanceLinkGetObjectValue()` and then use `TEGetType()` on the returned value to determine if it is a TEString or TETable.


Menus
-----

TELinkTypeInt and TELinkTypeString can have a list of choices associated with them, suitable for presentation to the user as a menu.

    if (TEInstanceLinkHasChoices(instance, identifier))
    {
        TEStringArray *labels = nullptr;
        result = TEInstanceLinkGetChoiceLabels(instance, identifier, &labels);
        if (result == TEResultSuccess && labels)
        {
            // ...
            TERelease(&labels);
        }
    }

For TELinkTypeInt, the associated value for a menu item is its index. For TELinkTypeString, `TEInstanceLinkGetChoiceValues()` returns a list of values, ordered to match the labels. Note that this list should not be considered exhaustive and users should be allowed to enter their own values as well as those in this list.


Working with TELinkTypeTexture
------------------------------

The TEGraphicsContext associated with an instance affects the behaviour of input and output links, so the first task is to associate a graphics context of a suitable type.

One-time setup (Metal):

    TEMetalContext *context;
    TEResult result = TEMetalContextCreate(device, &context);

One-time association (all graphics APIs):

    if (result == TEResultSuccess)
    {
    	result = TEInstanceAssociateGraphicsContext(instance, context);
    }
    if (result != TEResultSuccess)
    {
        // deal with the error
    }

An instance will accept inputs and emit outputs of a TETextureType which is shareable and appropriate for the associated graphics context.

For a TEMetalContext or TEVulkanContext, the shareable type is either TEIOSurfaceTexture or TEMetalTexture (the underlying MTLTexture must have been created as shareable).

A TEOpenGLContext allows you to work with native OpenGL textures and have the context do the work of copying and instantiating the native texture types from the shareable type used by the instance. Even when using these contexts, best performance is achieved by setting inputs as the shareable type directly, saving the copy stage performed by the TEGraphicsContext. In the OpenGL case the shareable texture type is TEIOSurfaceTexture.

If you are setting a shareable texture type on input links directly, TouchEngine will use the lifetime of the TETextures you create to manage the lifetime of internal resources. For this reason, performance is improved by recycling textures in a pool, and keeping the associated TETexture alive for the lifetime of the underlying resource. To know when a texture is in use by TouchEngine, use the TEObjectEvent parameter of the TETexture's callback and monitor TEObjectEventBeginUse and TEObjectEventEndUse. When TEObjectEventEndUse is received, the texture can be returned to your pool for reuse. The example project has a class, `TCHTexturePool`, which manages this for you.

If you are instantiating output textures directly from a shareable type (TEMetalTexture or TEIOSurfaceTexture), then there will usually be benefit in keeping a cache of instantiated textures, as TouchEngine will recycle textures internally. The lifetime of TETextures got from outputs indicates to TouchEngine when the output is in use by you, and so you *must* TERelease them when you are finished with them to allow them to be recycled - ie do *not* TERetain the TETexture itself in your output texture cache, but use the associated shared resource (the `IOSurfaceRef` or `MTLSharedEventHandle`) value to map TETextures to your instantiated textures. You can register a callback for the TETextures you receive from the instance, and monitor TEObjectEventRelease to know when an instantiated texture should be deleted from your cache. The example project has a class, `TCHResourceCache`, which manages this for you. When using an OpenGL context, this is all handled for you if you use `TEOpenGLContextCreateTexture()` to instantiate the native texture from the shareable type.

Setting an input (Metal):

    // Here we set a short-lived texture, but see above for guidance around texture re-use
    TEMetalTexture *texture = TEMetalTextureCreate(tex, TETextureOriginTopLeft, kTETextureComponentMapIdentity, NULL, NULL);
    TEResult result = TEInstanceLinkSetTextureValue(instance, identifier, texture, context);
    // Release the texture - the instance will have retained it if necessary
    TERelease(&texture);

Getting an output (Metal):

    TETexture *value;
    TEResult result = TEInstanceLinkGetTextureValue(instance, identifier, TELinkValueCurrent, &value);
    if (result == TEResultSuccess && value != NULL)
    {
        if (TETextureGetType(value) == TETextureTypeMetal)
        {
            TEMetalTexture *texture = (TEMetalTexture *)value;
            // Use the instantiated texture here
            // ...
        }
    }
    TERelease(&value);


GPU Synchronization
-------------------

Usage of texture inputs and outputs must be synchronized between the host and TouchEngine. TouchEngine describes this operation as a texture transfer. The exact process depends on the graphics API in use - as determined by the TEGraphicsContext associated with the instance.

#### OpenGL

There are no texture transfer operations at the host level if you operate only with TEOpenGLTextures, but you must bracket GPU usage of output textures with calls to `TEOpenGLTextureLock()` and `TEOpenGLTextureUnlock()`.

#### Metal

Texture transfers are required for inputs and outputs, which are either TEIOSurfaceTextures or TEMetalTextures. The transfer is done with a Metal shared event (as a TEMetalSemaphore).

When transferring a texture *to* TouchEngine, schedule a signal for the event with a known value, then pass the event and value to `TEInstanceAddTextureTransfer()`. TouchEngine will schedule a wait for the provided value before utilising the texture.

When transferring a texture *from* TouchEngine, `TEInstanceGetTextureTransfer()` will return an event and wait-value. Schedule a wait for the returned value before utilising the texture.

#### Vulkan

Because a texture transfer can require a Vulkan memory barrier operation, extra steps are required. TEVulkan.h has functions which supplement the texture transfer functions in TEInstance.h when working with a Vulkan graphics context.

Texture transfers are required for inputs and outputs, which are either TEIOSurfaceTextures or TEMetalTextures. The transfer is done with a Metal shared event (as a TEMetalSemaphore). The texture and semaphore types can be imported as Vulkan images and timeline semaphores using the available Vulkan extensions.

When transferring textures the contents of which should be kept (ie transferring inputs to TouchEngine, and outputs from TouchEngine), a Vulkan memory barrier is required. For inputs, perform the barrier to the image layout returned from `TEInstanceGetVulkanReleaseImageLayout()` and then provide the old and new layouts to `TEInstanceAddVulkanTextureTransfer()`. You can change the image layout the instance transfers textures to by calling `TEInstanceSetVulkanAcquireImageLayout()` once. This will determine the new layout you receive from `TEInstanceGetVulkanTextureTransfer()`.

When transferring textures the contents of which can be discarded, use a regular texture transfer with `TEInstanceAddTextureTransfer()` or `TEInstanceGetTextureTransfer()`.

When transferring a texture *to* TouchEngine, schedule a signal for the semaphore with a known value, then pass the semaphore and value to `TEInstanceAddVulkanTextureTransfer()` or `TEInstanceAddTextureTransfer()`. TouchEngine will schedule a wait for the provided value before utilising the texture.
When transferring a texture *from* TouchEngine, `TEInstanceGetTextureTransfer()` or `TEInstanceGetVulkanTextureTransfer()` will return a semaphore and wait-value. Schedule a wait for the returned value before utilising the texture.


Allowing users to reference known TouchDesigner objects
-------------------------------------------------------

In some cases your users may want to refer to inputs and outputs by the name they have used for entities inside a loaded TouchDesigner component. Combined use of the `name` and `domain` members of the `TELinkInfo` struct allow for a one-to-one reference to entities within a component. For example, a user may wish to refer to a TouchDesigner operator with the name "out1" to locate an output. To match that, locate a link with the domain `TELinkDomainOperator` and name "out1". Note that `name` is only a reliable identifier within a single domain - the same name can occur in multiple domains.

If you need to use domains in UI, the two domains which users might expect to be able to refer to, and textual names and abbreviations which will be familiar to them, are:

|Domain                |Name      |Abbreviation |
|----------------------|----------|-------------|
|TELinkDomainParameter |Parameter |par          |
|TELinkDomainOperator  |Operator  |op           |


Signing and the Hardened Runtime
--------------------------------

When using the macOS Hardened Runtime with TouchEngine.framework you will have to manually sign some components of the framework. Xcode's "Code Sign on Copy" option only signs the top-level library. The following correctly signs all the components of the framework to satisfy requirements for development, archiving and notarization (replace `<IDENTITY>` with your codesigning identity):

	codesign --force -s <IDENTITY> -o runtime TouchEngine.framework/Versions/A/Frameworks/IPM.framework/Versions/A/ca.derivative.IPMAgent
	codesign --force -s <IDENTITY> TouchEngine.framework/Versions/A/Frameworks/IPM.framework/Versions/A/IPM
	codesign --force -s <IDENTITY> TouchEngine.framework/Versions/A/Frameworks/libTPC.dylib
	codesign --force -s <IDENTITY> TouchEngine.framework/Versions/A/Frameworks/libTouchEngine.dylib
	codesign --force -s <IDENTITY> TouchEngine.framework/Versions/A/TouchEngine
