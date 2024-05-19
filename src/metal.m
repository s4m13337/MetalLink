#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_device.h"
#include "wstp.h"
#include "utilities.h"

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

int main(int argc, char* argv[]){
    init();
    return WSMain(argc, argv);
}