#ifndef METAL_DEVICE_H
#define METAL_DEVICE_H
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

int initializeDevice();
int createLibrary();
int initializePipelineCache();
int createPipeline(NSString *);
int createCommandQueue();
int deviceInformation();

extern id<MTLDevice> device;
extern id<MTLLibrary> library;
extern id<MTLFunction> kernelFunction;
extern id<MTLComputePipelineState> computePipelineState;
extern id<MTLCommandQueue> commandQueue;
extern id<MTLCommandBuffer> commandBuffer;
extern id<MTLComputeCommandEncoder> computeEncoder;
extern NSMutableDictionary<NSString *, id<MTLComputePipelineState>> *pipelineCache;

#endif