#ifndef HSV_LIB
#define HSV_LIB

float3 hue2rgb(float hue) {
    hue = frac(hue); //only use fractional part
    float r = abs(hue * 6 - 3) - 1; //red
    float g = 2 - abs(hue * 6 - 2); //green
    float b = 2 - abs(hue * 6 - 4); //blue
    float3 rgb = float3(r,g,b); //combine components
    rgb = saturate(rgb); //clamp between 0 and 1
    return rgb;
}

float3 hsv2rgb(float3 hsv)
{
    float3 rgb = hue2rgb(hsv.x); //apply hue
    rgb = lerp(1, rgb, hsv.y); //apply saturation
    rgb = rgb * hsv.z; //apply value
    return rgb;
}

float3 rgb2hsv(float3 rgb)
{
    float maxComponent = max(rgb.r, max(rgb.g, rgb.b));
    float minComponent = min(rgb.r, min(rgb.g, rgb.b));
    float diff = maxComponent - minComponent;
    float hue = 0;
    if(maxComponent == rgb.r) {
        hue = 0+(rgb.g-rgb.b)/diff;
    } else if(maxComponent == rgb.g) {
        hue = 2+(rgb.b-rgb.r)/diff;
    } else if(maxComponent == rgb.b) {
        hue = 4+(rgb.r-rgb.g)/diff;
    }
    hue = frac(hue / 6);
    float saturation = diff / maxComponent;
    float value = maxComponent;
    return float3(hue, saturation, value);
}

#endif