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

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

struct FillRasterizerData
{
	float4 position [[position]];
};

vertex FillRasterizerData
fillVertexShader(uint vertexID [[vertex_id]],
			 constant TextureFillVertex *vertices [[buffer(VertexInputIndexVertices)]],
			 constant vector_uint2 *viewportSizePointer [[buffer(VertexInputIndexViewportSize)]])
{
	FillRasterizerData out;
	
	vector_float2 viewportSize = vector_float2(*viewportSizePointer);
	float2 pixelSpacePosition = vertices[vertexID].position.xy;

	out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
	out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

	return out;
}

fragment float4
fillFragmentShader(FillRasterizerData in [[stage_in]],
				   constant TextureFillFragmentArguments *arguments [[buffer(FragmentInputIndexArguments)]])
{
	float2 mid = arguments->midpoint;
	
	float offset = distance(mid, in.position.xy);
	
	float edge = min(mid.x, mid.y) * arguments->scale;
	
	float amount = smoothstep(edge, edge - 3, offset);
		
	return float4(mix(arguments->red.x, arguments->red.y, amount),
                  mix(arguments->green.x, arguments->green.y, amount),
                  mix(arguments->blue.x, arguments->blue.y, amount),
                  1.0);
}

struct DrawRasterizerData
{
	float4 position [[position]];
	float2 textureCoordinate;
};

vertex DrawRasterizerData
drawVertexShader(uint vertexID [[ vertex_id ]],
			 constant DrawVertex *vertexArray [[ buffer(VertexInputIndexVertices) ]],
			 constant vector_uint2 *viewportSizePointer  [[ buffer(VertexInputIndexViewportSize) ]])

{

	DrawRasterizerData out;

	float2 pixelSpacePosition = vertexArray[vertexID].position.xy;

	float2 viewportSize = float2(*viewportSizePointer);

	out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
	out.position.xy = pixelSpacePosition / (viewportSize / 2.0);

	out.textureCoordinate = vertexArray[vertexID].textureCoordinate;

	return out;
}

fragment float4
drawSamplingShader(DrawRasterizerData in [[stage_in]],
			   texture2d<half> colorTexture [[ texture(TextureIndexBaseColor) ]])
{
	constexpr sampler sampler(mag_filter::linear, min_filter::linear);

	const half4 colorSample = colorTexture.sample(sampler, in.textureCoordinate);

	return float4(colorSample);
}
