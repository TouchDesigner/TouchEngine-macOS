//
//  Shaders.metal
//  TouchEngineTest
//
//  Created by Derivative on 08/07/2022.
//

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
	
	amount = mix(0.4, 0.9, amount);
	
	return float4(amount, amount, amount, 1.0);
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
