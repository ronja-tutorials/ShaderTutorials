#ifndef WHITE_NOISE
#define WHITE_NOISE

//to 1d functions


float rand4dTo1d(float4 value, float4 dotDir = float4(12.9898, 78.233, 37.719, 17.4265)){
	float4 smallValue = cos(value);
	float random = dot(smallValue, dotDir);
	random = frac(sin(random) * 143758.5453);
	return random;
}

//get a scalar random value from a 3d value
float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
	//make value smaller to avoid artefacts
	float3 smallValue = cos(value);
	//get scalar value from 3d vector
	float random = dot(smallValue, dotDir);
	//make value more random by making it bigger and then taking the factional part
	random = frac(sin(random) * 143758.5453);
	return random;
}

float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)){
	float2 smallValue = cos(value);
	float random = dot(smallValue, dotDir);
	random = frac(sin(random) * 143758.5453);
	return random;
}

float rand1dTo1d(float3 value, float mutator = 0.546){
	float random = frac(sin(value + mutator) * 143758.5453);
	return random;
}

//to 2d functions

float2 rand3dTo2d(float3 value){
	return float2(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155))
	);
}

float2 rand2dTo2d(float2 value){
	return float2(
		rand2dTo1d(value, float2(12.989, 78.233)),
		rand2dTo1d(value, float2(39.346, 11.135))
	);
}

float2 rand1dTo2d(float value){
	return float2(
		rand2dTo1d(value, 3.9812),
		rand2dTo1d(value, 7.1536)
	);
}

//to 3d functions

float3 rand3dTo3d(float3 value){
	return float3(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
		rand3dTo1d(value, float3(73.156, 52.235, 09.151))
	);
}

float3 rand2dTo3d(float2 value){
	return float3(
		rand2dTo1d(value, float2(12.989, 78.233)),
		rand2dTo1d(value, float2(39.346, 11.135)),
		rand2dTo1d(value, float2(73.156, 52.235))
	);
}

float3 rand1dTo3d(float value){
	return float3(
		rand1dTo1d(value, 3.9812),
		rand1dTo1d(value, 7.1536),
		rand1dTo1d(value, 5.7241)
	);
}

// to 4d // TEMP
float4 rand4dTo4d(float4 value){
	return float4(
		rand4dTo1d(value, float4(12.989, 78.233, 37.719, -12.15)),
		rand4dTo1d(value, float4(39.346, 11.135, 83.155, -11.44)),
		rand4dTo1d(value, float4(73.156, 52.235, 09.151, 62.463)),
		rand4dTo1d(value, float4(-12.15, 12.235, 41.151, -1.135))
	);
}

#endif