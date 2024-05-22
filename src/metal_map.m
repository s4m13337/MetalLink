#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"

void processMapAsync(float *data, NSUInteger length, float *result) {
    @autoreleasepool{
    NSUInteger CHUNK_SIZE = 100000;
    dispatch_group_t group = dispatch_group_create();
    NSUInteger numChunks = (length + CHUNK_SIZE - 1) / CHUNK_SIZE;
    
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
            
            id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
            id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
            [computeEncoder setComputePipelineState:computePipelineState];
            [computeEncoder setBuffer:dataBuffer offset:0 atIndex:0];
            [computeEncoder setBuffer:resultBuffer offset:0 atIndex:1];
            
            NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
            NSUInteger threadgroupCount = (chunkSize + threadsPerThreadgroup - 1) / threadsPerThreadgroup;
            MTLSize threadgroupSize = MTLSizeMake(threadsPerThreadgroup, 1, 1);
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

    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    
    logToFile("Getting data from Mathematica");
    t_start = clock();
    MNumericArray input_array = MArgument_getMNumericArray(Args[0]);;
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

    createPipeline(@"map");

    logToFile("Starting asynchronous process");

    processMapAsync(data, length, result);

    logToFile("Control has returned to main");

    /*
    logToFile("Creating buffers");
    t_start = clock();
    id<MTLBuffer> dataBuffer = [
        device newBufferWithBytes:data 
        length:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];

    id<MTLBuffer> resultBuffer = [
        device newBufferWithLength:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Buffers created in %.12f seconds", t_elapsed);
    logToFile(message);

    

    // Set up command encoder
    commandBuffer = [commandQueue commandBuffer];
    computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:computePipelineState];
    [computeEncoder setBuffer:dataBuffer offset:0 atIndex:0];
    [computeEncoder setBuffer:resultBuffer offset:0 atIndex:1];        
    logToFile("Command queue ready");

    // Set up threadgroups
    logToFile("Calculating threadgroups");
    NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
    NSUInteger threadExecutionWidth = computePipelineState.threadExecutionWidth;
    NSUInteger threadgroupCount = (length + threadsPerThreadgroup - 1) / threadsPerThreadgroup;
    MTLSize threadgroupSize = MTLSizeMake(threadsPerThreadgroup, 1, 1);
    MTLSize threadgroups = MTLSizeMake(threadgroupCount, 1, 1);
    sprintf(message, "Threads per threadgroup: %lu", (unsigned long) threadsPerThreadgroup);
    logToFile(message);
    sprintf(message, "Thread execution width: %lu", (unsigned long)threadExecutionWidth);
    logToFile(message);
    sprintf(message, "Threadgroups allocated: %lu", (unsigned long)threadgroupCount);
    logToFile(message);

    // Dispatch compute kernel & end encoding
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
    [computeEncoder endEncoding];
    logToFile("Encoding finished, Dispatched commands to GPU");

    // Execute command buffer & Wait until completion
    t_start = clock();
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Computation on GPU completed in %.6f seconds", t_elapsed);
    logToFile(message);
    logToFile("Computation on GPU complete. Returning back...");

    // Read back results
    logToFile("Starting to copy buffer contents");
    memcpy(result, [resultBuffer contents], sizeof(float)*length);
    logToFile("Buffer contents copied"); */

    // Return to WL
    MArgument_setMNumericArray(Res, output_array);

    return LIBRARY_NO_ERROR;
}   
    
    
