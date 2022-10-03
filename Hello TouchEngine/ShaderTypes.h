/* Shared Use License: This file is owned by Derivative Inc. (Derivative)
* and can only be used, and/or modified for use, in conjunction with
* Derivative's TouchDesigner software, and only if you are a licensee who has
* accepted Derivative's TouchDesigner license or assignment agreement
* (which also govern the use of this file). You may share or redistribute
* a modified version of this file provided the following conditions are met:
*
* 1. The shared file or redistribution must retain the information set out
* above and this list of conditions.
* 2. Derivative's name (Derivative Inc.) or its trademarks may not be used
* to endorse or promote products derived from this file without specific
* prior written permission from Derivative.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef struct
{
	vector_float2 position;
} TextureFillVertex;

typedef struct
{
	vector_float2 midpoint;
	float scale;
} TextureFillFragmentArguments;

typedef struct
{
	vector_float2 position;
	vector_float2 textureCoordinate;
} DrawVertex;

typedef enum VertexInputIndex
{
	VertexInputIndexVertices = 0,
	VertexInputIndexViewportSize = 1,
} VertexInputIndex;

typedef enum FragmentInputIndex
{
	FragmentInputIndexArguments = 0,
} FragmentInputIndex;

typedef enum TextureIndex
{
	TextureIndexBaseColor = 0,
} TextureIndex;

#endif /* ShaderTypes_h */
