#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"

EXTERN_C DLLEXPORT int metalMap(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    
    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    
    MNumericArray input_array = MArgument_getMNumericArray(Args[0]);;
    float *data = naFuns->MNumericArray_getData(input_array);
    mint rank = naFuns->MNumericArray_getRank(input_array);
    const mint *dimensions; 
    dimensions = naFuns->MNumericArray_getDimensions(input_array);
    int length = (int) dimensions[0];

    MNumericArray output_array = NULL;
    numericarray_data_t type = MNumericArray_Type_Real32;
    naFuns->MNumericArray_new(type, rank, dimensions, &output_array);
    float *result = naFuns->MNumericArray_getData(output_array);
    
    // Variables for logging, measuring time
    char *message = NULL;
    clock_t t_start, t_end;
    double t_elapsed;
    message = (char *) malloc(100 * sizeof(char));

    id<MTLBuffer> dataBuffer = [
        device newBufferWithBytes:data 
        length:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];

    id<MTLBuffer> resultBuffer = [
        device newBufferWithLength:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];

    createPipeline(@"map");

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
    logToFile("Buffer contents copied");

    // Return to WL
    MArgument_setMNumericArray(Res, output_array);

    return LIBRARY_NO_ERROR;
}   
    
    
