kernel void map(
    device const float* data [[buffer(0)]],
    device float* result [[buffer(1)]],
    uint index [[thread_position_in_grid]]) {
    result[index] = sin(data[index]);
}