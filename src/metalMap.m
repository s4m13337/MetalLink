#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"
#include <string.h>

// Obtain function ID for map function
int getFunctionId(char *functionName){
    int functionId = -1;
    const char *function[] = {
        "Sin", "Cos", "Tan", 
        "ArcCos", "ArcSin", "ArcTan",
        "Cosh", "Sinh", "Exp", 
        "Log", "Log10", "Sqrt", 
        "Ceiling", "Floor", "Abs"
    };
    for(int i = 0; i < 15; i++){
        if(strcmp(function[i], functionName) == 0 ){
            functionId = i;
            break;
        }   
    }
    return functionId;
}

void processAsyncMap(float *data, NSUInteger length, int function_id, float *result) {
    @autoreleasepool{
        // Create pipeline & calculate threadgroups dimensions
        createPipeline(@"map");
        NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
        MTLSize threadgroupSize = MTLSizeMake(threadsPerThreadgroup, 1, 1);

        // Data chucks per asynchronous process
        NSUInteger chunkSize = 100000;
        NSUInteger numChunks = (length + chunkSize - 1) / chunkSize;
        
        // Create dispatch group and loop through each data chunk
        dispatch_group_t group = dispatch_group_create();
        for (NSUInteger chunkIndex = 0; chunkIndex < numChunks; chunkIndex++) {
            dispatch_group_enter(group);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSUInteger chunkStart = chunkIndex * chunkSize;
                NSUInteger currentChunkSize = MIN(chunkSize, length - chunkStart);
                
                // Create buffers
                id<MTLBuffer> dataBuffer = [
                    device newBufferWithBytes:(data + chunkStart)
                    length:sizeof(float) * currentChunkSize
                    options:MTLResourceStorageModeShared
                ];
                id<MTLBuffer> resultBuffer = [
                    device newBufferWithLength:sizeof(float) * currentChunkSize
                    options:MTLResourceStorageModeShared
                ];

                id<MTLBuffer> functionIdBuffer = [
                    device newBufferWithBytes:&function_id 
                    length:sizeof(int) 
                    options:MTLResourceStorageModeShared
                ];
                
                // Encode data into buffers
                id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
                id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
                [computeEncoder setComputePipelineState:computePipelineState];
                [computeEncoder setBuffer:dataBuffer offset:0 atIndex:0];
                [computeEncoder setBuffer:resultBuffer offset:0 atIndex:1];
                [computeEncoder setBuffer:functionIdBuffer offset:0 atIndex:2];
                
                // Create threadgroups
                NSUInteger threadgroupCount = (currentChunkSize + threadsPerThreadgroup - 1) / threadsPerThreadgroup;
                MTLSize threadgroups = MTLSizeMake(threadgroupCount, 1, 1);
                
                // Dispatch task to GPU
                [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
                [computeEncoder endEncoding];
                
                // Copy back result on completion of a process
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
                    memcpy(result + chunkStart, resultBuffer.contents, sizeof(float) * currentChunkSize);
                    dispatch_group_leave(group);
                }];
                
                [commandBuffer commit];

            });
        }
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }
}

int metalMap(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    // Declarations for function name and function Id (argument 1)
    char *functionName =  MArgument_getUTF8String(Args[0]);
    int functionId;
    functionId = getFunctionId(functionName);

    // Declarations for data from Mathematica (argument 2)
    MNumericArray inputArray = MArgument_getMNumericArray(Args[1]);;
    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    float *data = naFuns->MNumericArray_getData(inputArray);
    mint rank = naFuns->MNumericArray_getRank(inputArray);
    const mint *dimensions; 
    dimensions = naFuns->MNumericArray_getDimensions(inputArray);
    int length = (int) dimensions[0];

    // Declaration & initialization for output array
    MNumericArray outputArray = NULL;
    numericarray_data_t type = MNumericArray_Type_Real32;
    naFuns->MNumericArray_new(type, rank, dimensions, &outputArray);
    float *result = naFuns->MNumericArray_getData(outputArray);

    // Send job to GPU
    processAsyncMap(data, length, functionId, result);

    // Return result to Mathematica
    MArgument_setMNumericArray(Res, outputArray);
    return LIBRARY_NO_ERROR;
}