kernel void image_negative_bit8(
    texture2d<ushort, access::read> inTexture [[ texture(0) ]], 
    texture2d<ushort, access::write> outTexture [[ texture(1) ]], 
    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    ushort4 color = inTexture.read(gid);
    color.rgb = 255 - color.rgb;
    outTexture.write(color, gid);
}

kernel void image_negative_bit16(
    texture2d<ushort, access::read> inTexture [[ texture(0) ]], 
    texture2d<ushort, access::write> outTexture [[ texture(1) ]], 
    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    ushort4 color = inTexture.read(gid);
    color.rgb = 65535 - color.rgb;
    outTexture.write(color, gid);
}

kernel void image_negative_real32(
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

