//
//  ShaderTypes.h
//  TouchEngineTest
//
//  Created by Derivative on 08/07/2022.
//

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
