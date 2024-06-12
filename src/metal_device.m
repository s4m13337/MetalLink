#import "metal_device.h"
#include "utilities.h"

id<MTLDevice> device = nil;
id<MTLLibrary> library = nil;
id<MTLFunction> kernelFunction = nil;
id<MTLComputePipelineState> computePipelineState = nil;
id<MTLCommandQueue> commandQueue = nil;
id<MTLCommandBuffer> commandBuffer = nil;
id<MTLComputeCommandEncoder> computeEncoder = nil;
NSMutableDictionary<NSString *, id<MTLComputePipelineState>> *pipelineCache;

int initializeDevice(){
    // Initialize device
    device = MTLCreateSystemDefaultDevice();
    if(!device) { logToFile("Device creation failed"); return -1; }
    logToFile("Metal device instance created");
    if(MPSSupportsMTLDevice(device)) { 
        logToFile("MPS is supported");
    } else {
        logToFile("MPS is not supported");
    }
    return 0;
}

int createLibrary(){
    // Create library from source file
    NSError *error = nil;
    NSString *source = [
        NSString stringWithContentsOfFile:@"./lib/library.metal" 
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
    return 0;
}

int initializePipelineCache() {
    pipelineCache = [NSMutableDictionary dictionary];
    if(!pipelineCache){
        logToFile("Failed creating pipeline cache!");
    } else {
        logToFile("Pipeline cache created");
    }
    return 0;
}

int createPipeline(NSString *func_name){
    NSError *error = nil;
    char *message;
    message = (char *) malloc(100 * sizeof(char));
    //Load pipeline from cache
    sprintf(message, "Checking cache if function %s exists in pipeline", [func_name UTF8String]);
    logToFile(message);
    computePipelineState = pipelineCache[func_name];
    
    if(!computePipelineState){
        logToFile("Function not found in pipeline. Creating new pipeline");
        kernelFunction = [library newFunctionWithName:func_name];
        if(!kernelFunction){
            logToFile("Error loading kernel function"); 
            return -1; 
        }
        sprintf(message, "Successfully loaded function: %s", [func_name UTF8String]);
        logToFile(message);
        

        computePipelineState = [
            device newComputePipelineStateWithFunction:kernelFunction
            error:&error
        ];
        if (!computePipelineState) { 
            sprintf(message, "Compute PSO failed for function %s", [func_name UTF8String]);
            logToFile(message); 
            return -1; 
        } else {
            sprintf(message, "Compute PSO created for function %s", [func_name UTF8String]);
            logToFile(message);
        }

        logToFile("Caching pipeline state");
        pipelineCache[func_name] = computePipelineState;
        return 0;
    
    }

    logToFile("Pipeline loaded from cache");
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