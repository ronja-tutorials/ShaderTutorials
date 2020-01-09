//avoid multiple imports
#ifndef INTERPOLATION
#define INTERPOLATION

/* //hlsl supports linear interpolation intrinsically so this isn't needed
float lerp(float from, float to, float rel){
    return ((1 - rel) * from) + (rel * to);
}
*/

float invLerp(float from, float to, float value) {
    return (value - from) / (to - from);
}

float4 invLerp(float4 from, float4 to, float4 value) {
    return (value - from) / (to - from);
}

float remap(float origFrom, float origTo, float targetFrom, float targetTo, float value){
    float rel = invLerp(origFrom, origTo, value);
    return lerp(targetFrom, targetTo, rel);
}

float4 remap(float4 origFrom, float4 origTo, float4 targetFrom, float4 targetTo, float4 value){
    float4 rel = invLerp(origFrom, origTo, value);
    return lerp(targetFrom, targetTo, rel);
}

#endif