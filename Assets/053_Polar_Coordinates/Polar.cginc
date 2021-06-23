#ifndef POLAR_COORDINATES
#define POLAR_COORDINATES

float2 toPolar(float2 cartesian){
    float distance = length(cartesian);
    float angle = atan2(cartesian.y, cartesian.x);
    return float2(angle / UNITY_TWO_PI, distance);
}

float2 toCartesian(float2 polar){
    float2 cartesian;
    sincos(polar.x * UNITY_TWO_PI, cartesian.y, cartesian.x);
    return cartesian * polar.y;
}

#endif
