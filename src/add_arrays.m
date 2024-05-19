#include "metal_device.h"
#include "utilities.h"
#include "wstp.h"

void addArrays(){    
    
    float *array1 = NULL, *array2 = NULL;
    int *dims1 = NULL, *dims2 = NULL;
    char **head1 = NULL, **head2 = NULL;
    int d1 = 0, d2 = 0;
    
    // Variables for logging, measuring time
    char *message = NULL;
    clock_t t_start, t_end;
    double t_elapsed;

    message = (char *) malloc(100 * sizeof(char));

    // Get data from Mathematica
    logToFile("Getting data from Mathematica");
    logToFile("Fetching array 1");
    t_start = clock();
    WSGetReal32Array(stdlink, &array1, &dims1, &head1, &d1);
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Fetched array 1 in %.6f seconds", t_elapsed);
    logToFile(message);
    logToFile("Fetching array 2");
    t_start = clock();
    WSGetReal32Array(stdlink, &array2, &dims2, &head2, &d2);
    t_end = clock();
    t_elapsed = measureTime(t_start, t_end);
    sprintf(message, "Fetched array 2 in %.6f seconds", t_elapsed);
    logToFile(message);
    
    int length = *dims1;
    float *result = (float *)malloc(sizeof(float) * length);
    
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
    WSPutReal32List(stdlink, (float *)result, length);
    
    // Cleanup resources
    WSReleaseReal32Array(stdlink, array1, dims1, head1, d1);
    WSReleaseReal32Array(stdlink, array2, dims2, head2, d2);
    free(result);
    free(message);
    return;
}