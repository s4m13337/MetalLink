#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"

int init(){
    initializeDevice();
    deviceInformation();
    createLibrary();
    createPipeline();
    createCommandQueue();
    //Threadgroup information
    threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
    threadExecutionWidth = computePipelineState.threadExecutionWidth;
    return 0;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData) {
    init();
    return LIBRARY_NO_ERROR;
}

EXTERN_C DLLEXPORT void WolframLibrary_uninitialize(WolframLibraryData libData) {
    return;
}