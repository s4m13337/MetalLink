kernel void map(
    device const float* data [[buffer(0)]],
    device float* result [[buffer(1)]],
    constant int* operator_id [[buffer(2)]],
    uint index [[thread_position_in_grid]]) {

    switch(*operator_id){
        case 0:
            result[index] = sin(data[index]);
            break;
        case 1:
            result[index] = cos(data[index]);
            break;
        case 2:
            result[index] = tan(data[index]);
            break;
        case 3:
            result[index] = acos(data[index]);
            break;
        case 4:
            result[index] = asin(data[index]);
            break;
        case 5:
            result[index] = atan(data[index]);
            break;
        case 6:
            result[index] = cosh(data[index]);
            break;
        case 7:
            result[index] = sinh(data[index]);
            break;
        case 8:
            result[index] = exp(data[index]);
            break;
        case 9:
            result[index] = log(data[index]);
            break;
        case 10:
            result[index] = log10(data[index]);
            break;
        case 11:
            result[index] = sqrt(data[index]);
            break;
        case 12:
            result[index] = ceil(data[index]);
            break;
        case 13:
            result[index] = floor(data[index]);
            break;
        case 14:
            result[index] = abs(data[index]);
            break;
        default:
            result[index] = data[index];
            break;
    }  
}