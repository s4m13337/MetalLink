kernel void add_arrays(
    device const float* array1 [[buffer(0)]],
    device const float* array2 [[buffer(1)]],
    device float* result [[buffer(2)]],
    uint index [[thread_position_in_grid]]) {
    result[index] = array1[index] + array2[index];
}
