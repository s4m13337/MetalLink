kernel void image_negative(
    texture2d<float, access::read> inTexture [[ texture(0) ]], 
    texture2d<float, access::write> outTexture [[ texture(1) ]], 
    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    float4 color = inTexture.read(gid);
    color.rgb = 1.0 - color.rgb;
    outTexture.write(color, gid);
}