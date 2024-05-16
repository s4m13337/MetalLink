#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "wstp.h"
#include "utilities.h"

id<MTLDevice> device;
id<MTLLibrary> library;
id<MTLFunction> kernelFunction;
id<MTLComputePipelineState> computePipelineState;
id<MTLCommandQueue> commandQueue;
id<MTLCommandBuffer> commandBuffer;

char* deviceName(){
    return (char *)[[device name] UTF8String];
}

void deviceRecommendedMaxWorkingSetSize(){
    uint64_t memory = [device recommendedMaxWorkingSetSize];
    WSPutInteger64(stdlink, memory);
}

void deviceMaxBufferLength(){
    uint64_t maxBufferLength = [device maxBufferLength];
    WSPutInteger64(stdlink, maxBufferLength);
}

char* deviceHasUnifiedMemory(){
    return [device hasUnifiedMemory] ? "Unified" : "Dedicated";
}

void deviceMaxTransferRate(){
    uint64_t maxTransferRate = [device maxTransferRate];
    WSPutInteger64(stdlink, maxTransferRate);
}

void readFile(){
        NSString *filePath = @"add_arrays.metal";
        //NSString *currentDirectory = [[NSFileManager defaultManager] currentDirectoryPath];
        NSError *error = nil; // Declare the NSError pointer
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        //WSPutString(stdlink, (char *)[currentDirectory UTF8String]);
        if (fileContents == nil) {
            WSPutString(stdlink, (char *)[[error localizedDescription] UTF8String]);
        } else {
            WSPutString(stdlink, [fileContents UTF8String]);
        }
}

void addArrays(){    
    
    float *array1, *array2;
    int *dims1, *dims2;
    char **head1, **head2;
    int d1, d2;

    WSGetReal32Array(stdlink, &array1, &dims1, &head1, &d1);
    WSGetReal32Array(stdlink, &array2, &dims2, &head2, &d2);
    int length = *dims1;
    float result[length];
    
    // Create Metal buffers
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
    logToFile("Metal buffers created...");
  
    // Set up command encoder

    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:computePipelineState];
    [computeEncoder setBuffer:array1Buffer offset:0 atIndex:0];
    [computeEncoder setBuffer:array2Buffer offset:0 atIndex:1];
    [computeEncoder setBuffer:resultBuffer offset:0 atIndex:2];        
    logToFile("Command queue ready...");

    // Set up threadgroups
    NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
    NSUInteger threadExecutionWidth = computePipelineState.threadExecutionWidth;
    NSUInteger staticThreadgroupMemoryLength = computePipelineState.staticThreadgroupMemoryLength;
    NSUInteger threadgroupCount = (length + threadsPerThreadgroup - 1) / threadsPerThreadgroup;
    MTLSize threadgroupSize = MTLSizeMake(threadsPerThreadgroup, 1, 1);
    MTLSize threadgroups = MTLSizeMake(threadgroupCount, 1, 1);
    logToFile("Threadgroups calculated...");
    logToFile((char *)[NSString stringWithFormat:@"Threads per thread group: %lu", (unsigned long)threadsPerThreadgroup].UTF8String);
    logToFile((char *)[NSString stringWithFormat:@"Thread execution width: %lu", (unsigned long)threadExecutionWidth].UTF8String);
    logToFile((char *)[NSString stringWithFormat:@"Threadgroups allocated: %lu", (unsigned long)threadgroupCount].UTF8String);
    WSPutSymbol(stdlink, "Null");
    return;

    // Dispatch compute kernel & end encoding
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
    [computeEncoder endEncoding];
    logToFile("Encoding finished, Dispatched commands to GPU");

    // Execute command buffer & Wait until completion
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    logToFile("Computation on GPU complete. Returning back...");

    // Read back results
    memcpy(result, [resultBuffer contents], sizeof(float)*length);

    // Return to WL
    WSPutReal32List(stdlink, (float *)result, length);
    
    // Cleanup resources
    //free(array1);
    //free(array2);
    WSReleaseReal32Array(stdlink, array1, dims1, head1, d1);
    WSReleaseReal32Array(stdlink, array2, dims2, head2, d2);
    return;
}

int main(int argc, char* argv[]){
    
    // Initialize device
    device = MTLCreateSystemDefaultDevice();
    if(!device) { logToFile("Device creation failed"); return -1; }
    logToFile("Metal device instance created");

    // Create library from source file
    NSError *error = nil;
    NSString *source = [
        NSString stringWithContentsOfFile:@"add_arrays.metal" 
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

    // Compute Pipeline state
    computePipelineState = [
        device newComputePipelineStateWithFunction:kernelFunction
        error:&error
    ];
    if (!computePipelineState) { logToFile("Error creating compute pipeline state"); return -1; }
    logToFile("Pipeline state established");

    // Creating command queue & command buffer
    commandQueue = [device newCommandQueue];
    if(!commandQueue){ logToFile("Error: Failed creating command queue"); return -1; }
    commandBuffer = [commandQueue commandBuffer];
    if(!commandBuffer){ logToFile("Error: Failed creating command buffer"); return -1; }

    return WSMain(argc, argv);
}

