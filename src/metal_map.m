#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"
#include<string.h>

// Obtain operator ID for map function
int get_operator_id(char *operator_name){
    const char *operator[] = {
        "Sin", "Cos", "Tan", 
        "ArcCos", "ArcSin", "ArcTan",
        "Cosh", "Sinh", "Exp", 
        "Log", "Log10", "Sqrt", 
        "Ceiling", "Floor", "Abs"
    };
    for(int operator_id = 0; operator_id < 15; operator_id++){
        if(strcmp(operator[operator_id], operator_name) == 0 ){
            return operator_id;
        }   
    }
    return -1;
}

void processMapAsync(float *data, NSUInteger length, int operator_id, float *result) {
    @autoreleasepool{
        NSUInteger CHUNK_SIZE = 100000;
        dispatch_group_t group = dispatch_group_create();
        NSUInteger numChunks = (length + CHUNK_SIZE - 1) / CHUNK_SIZE;

        NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
        MTLSize threadgroupSize = MTLSizeMake(threadsPerThreadgroup, 1, 1);
        
        for (NSUInteger chunkIndex = 0; chunkIndex < numChunks; chunkIndex++) {
            
            dispatch_group_enter(group);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSUInteger chunkStart = chunkIndex * CHUNK_SIZE;
                NSUInteger chunkSize = MIN(CHUNK_SIZE, length - chunkStart);
                
                id<MTLBuffer> dataBuffer = [
                    device newBufferWithBytes:(data + chunkStart)
                    length:sizeof(float) * chunkSize
                    options:MTLResourceStorageModeShared
                ];
                id<MTLBuffer> resultBuffer = [
                    device newBufferWithLength:sizeof(float) * chunkSize
                    options:MTLResourceStorageModeShared
                ];

                id<MTLBuffer> operatorIdBuffer = [
                    device newBufferWithBytes:&operator_id 
                    length:sizeof(int) 
                    options:MTLResourceStorageModeShared
                ];
                
                id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
                id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
                [computeEncoder setComputePipelineState:computePipelineState];
                [computeEncoder setBuffer:dataBuffer offset:0 atIndex:0];
                [computeEncoder setBuffer:resultBuffer offset:0 atIndex:1];
                [computeEncoder setBuffer:operatorIdBuffer offset:0 atIndex:2];
                
                NSUInteger threadgroupCount = (chunkSize + threadsPerThreadgroup - 1) / threadsPerThreadgroup;
                MTLSize threadgroups = MTLSizeMake(threadgroupCount, 1, 1);
                
                [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
                [computeEncoder endEncoding];
                
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
                    memcpy(result + chunkStart, resultBuffer.contents, sizeof(float) * chunkSize);
                    dispatch_group_leave(group);
                }];
                
                [commandBuffer commit];

            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
}

EXTERN_C DLLEXPORT int metalMap(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    // Variables for logging, measuring time
    char *message = NULL;
    clock_t t_start, t_end;
    double t_elapsed;
    message = (char *) malloc(100 * sizeof(char));
    int func_id;

    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    
    logToFile("Getting data from Mathematica");
    t_start = clock();
    char *func_name =  MArgument_getUTF8String(Args[0]);
    MNumericArray input_array = MArgument_getMNumericArray(Args[1]);;
    float *data = naFuns->MNumericArray_getData(input_array);
    mint rank = naFuns->MNumericArray_getRank(input_array);
    const mint *dimensions; 
    dimensions = naFuns->MNumericArray_getDimensions(input_array);
    int length = (int) dimensions[0];
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Fetched data in %.12f seconds", t_elapsed);
    logToFile(message);

    logToFile("Initializing output array");
    t_start = clock();
    MNumericArray output_array = NULL;
    numericarray_data_t type = MNumericArray_Type_Real32;
    naFuns->MNumericArray_new(type, rank, dimensions, &output_array);
    float *result = naFuns->MNumericArray_getData(output_array);
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Output array initialized in %.12f seconds", t_elapsed);
    logToFile(message);

    func_id = get_operator_id(func_name);
    sprintf(message, "Selected function ID is %d", func_id);
    logToFile(message);

    createPipeline(@"map");

    logToFile("Starting asynchronous process");

    processMapAsync(data, length, func_id, result);

    logToFile("Control has returned to main");

    // Return to WL
    MArgument_setMNumericArray(Res, output_array);

    return LIBRARY_NO_ERROR;
}   
    
    
