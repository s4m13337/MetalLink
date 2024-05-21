#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"

EXTERN_C DLLEXPORT int addArrays(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    MNumericArray a0 = NULL, a1 = NULL;
    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    
    // Variables for logging, measuring time
    char *message = NULL;
    clock_t t_start, t_end;
    double t_elapsed;

    message = (char *) malloc(100 * sizeof(char));

    // Get data from Mathematica
    logToFile("Getting data from Mathematica");
    
    logToFile("Fetching array 1");
    t_start = clock();
    a0 = MArgument_getMNumericArray(Args[0]);
    float *array1 = naFuns->MNumericArray_getData(a0);
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Fetched array 1 in %.6f seconds", t_elapsed);
    logToFile(message);
    
    logToFile("Fetching array 2");
    t_start = clock();
    a1 = MArgument_getMNumericArray(Args[1]);
    float *array2 = naFuns->MNumericArray_getData(a1);
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Fetched array 2 in %.6f seconds", t_elapsed);
    logToFile(message);

    mint len1x = naFuns->MNumericArray_getDimensions(a0)[0];
    mint len1y = naFuns->MNumericArray_getDimensions(a0)[1];
    mint len2x = naFuns->MNumericArray_getDimensions(a1)[0];
    mint len2y = naFuns->MNumericArray_getDimensions(a1)[1];
    
    int length = (int) len1x;
    MNumericArray a2 = NULL;
    numericarray_data_t type = MNumericArray_Type_Real32;
    mint dims[2];
    dims[0] = len1x;
    dims[1] = len1y;
    mint rank = 1;
    naFuns->MNumericArray_new(type, rank, dims, &a2);
    float *result = naFuns->MNumericArray_getData(a2);
    
    // Create Metal buffers
    logToFile("Creating array buffers");
    t_start = clock();
    id<MTLBuffer> array1Buffer = [
        device newBufferWithBytes:array1 
        length:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];

    id<MTLBuffer> array2Buffer = [
        device newBufferWithBytes:array2 
        length:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];

    id<MTLBuffer> resultBuffer = [
        device newBufferWithLength:sizeof(float) * length 
        options:MTLResourceStorageModeShared
    ];
    
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Array buffers created in %.6f seconds", t_elapsed);
    logToFile(message);

    // Set up command encoder
    commandBuffer = [commandQueue commandBuffer];
    computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:computePipelineState];
    [computeEncoder setBuffer:array1Buffer offset:0 atIndex:0];
    [computeEncoder setBuffer:array2Buffer offset:0 atIndex:1];
    [computeEncoder setBuffer:resultBuffer offset:0 atIndex:2];        
    logToFile("Command queue ready");

    // Set up threadgroups
    logToFile("Calculating threadgroups");
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
    MArgument_setMNumericArray(Res, a2);
    /*[resultBuffer release];
    [array1Buffer release];
    [array2Buffer release];*/

    return LIBRARY_NO_ERROR;
}   
    
    
