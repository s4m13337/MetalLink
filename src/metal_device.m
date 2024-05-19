#import "metal_device.h"
#include "utilities.h"

id<MTLDevice> device = nil;
id<MTLLibrary> library = nil;
id<MTLFunction> kernelFunction = nil;
id<MTLComputePipelineState> computePipelineState = nil;
id<MTLCommandQueue> commandQueue = nil;
id<MTLCommandBuffer> commandBuffer = nil;
id<MTLComputeCommandEncoder> computeEncoder = nil;
NSUInteger threadsPerThreadgroup = 0;
NSUInteger threadExecutionWidth = 0;

int initializeDevice(){
    // Initialize device
    device = MTLCreateSystemDefaultDevice();
    if(!device) { logToFile("Device creation failed"); return -1; }
    logToFile("Metal device instance created");
    return 0;
}

int createLibrary(){
    // Create library from source file
    NSError *error = nil;
    NSString *source = [
        NSString stringWithContentsOfFile:@"lib/add_arrays.metal" 
        encoding:NSUTF8StringEncoding 
        error:&error
    ];
    MTLCompileOptions *options = [[MTLCompileOptions alloc] init];
    
    if(!source) { logToFile((char *)[[error localizedDescription] UTF8String]); return -1; }
    logToFile("Library sources loaded");

    library = [
        device newLibraryWithSource:source 
        options:options
        error:&error 
    ];
    if(!library){ logToFile((char *)[[error localizedDescription] UTF8String]); return -1; }
    logToFile("Library instance created");

    // Create kernel function instance
    kernelFunction = [library newFunctionWithName:@"add_arrays"];
    if (!kernelFunction) {logToFile("Failed to load kernel function"); return -1; }
    logToFile("Kernel functions loaded");

    return 0;
}

int createPipeline(){
    // Compute Pipeline state
    NSError *error = nil;
    computePipelineState = [
        device newComputePipelineStateWithFunction:kernelFunction
        error:&error
    ];
    if (!computePipelineState) { logToFile("Error creating compute pipeline state"); return -1; }
    logToFile("Pipeline state established");

    return 0;
}

int createCommandQueue(){
    // Creating command
    commandQueue = [device newCommandQueue];
    if(!commandQueue){ logToFile("Error: Failed creating command queue"); return -1; }
    return 0;
}

// Print device information
int deviceInformation(){
    char *message;
    message = (char *) malloc(100 * sizeof(char));
    sprintf(message, "Device name: %s", [[device name] UTF8String]);
    logToFile(message);
    sprintf(message, "Recommended maximum working memory: %ld bytes", (long)[device recommendedMaxWorkingSetSize]);
    logToFile(message);
    sprintf(message, "Maximum buffer length: %ld bytes", (long)[device maxBufferLength]);
    logToFile(message);
    [device hasUnifiedMemory] ? logToFile("Memory type: Unified") : logToFile("Memory type: Dedicated");
    sprintf(message, "Maximum transfer rate: %ld bytes/second", (long)[device maxTransferRate]);
    logToFile(message);
    return 0;
}