#include "metal_device.h"
#include "utilities.h"
#include "WolframLibrary.h"
#include "WolframImageLibrary.h"

void processImageNegative(float *data_in, mint row, mint col, float* data_out) {
    @autoreleasepool{
        // Create pipeline & calculate threadgroups dimensions
        createPipeline(@"image_negative");
        //NSUInteger threadsPerThreadgroup = computePipelineState.maxTotalThreadsPerThreadgroup;
        
        logToFile("Calculating threads");
        MTLSize threadgroupSize = MTLSizeMake(16, 16, 1);
        NSUInteger threadgroupWidth = (col + threadgroupSize.width - 1) / threadgroupSize.width;
        NSUInteger threadgroupHeight = (row + threadgroupSize.height - 1) / threadgroupSize.height;
        MTLSize threadgroups = MTLSizeMake(threadgroupWidth, threadgroupHeight, 1);

        logToFile("Creating textures");
        MTLTextureDescriptor *textureDescriptor = [
            MTLTextureDescriptor 
            texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float 
            width:col 
            height:row 
            mipmapped:NO
        ];
        id<MTLTexture> inTexture = [device newTextureWithDescriptor:textureDescriptor];
        id<MTLTexture> outTexture = [device newTextureWithDescriptor:textureDescriptor];
        
        logToFile("Drawing input image on textures");
        MTLRegion region = MTLRegionMake2D(0, 0, col, row);
        logToFile("2D region prepared, transferring image");
        [inTexture replaceRegion:region mipmapLevel:0 withBytes:data_in bytesPerRow:col * sizeof(float)];

        logToFile("Dispatching commands to GPU");
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:computePipelineState];
        [computeEncoder setTexture:inTexture atIndex:0];
        [computeEncoder setTexture:outTexture atIndex:1];

        [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupSize];
        [computeEncoder endEncoding];
        
        [commandBuffer commit];

        [commandBuffer waitUntilCompleted];

        [outTexture getBytes:data_out bytesPerRow:col * sizeof(float) fromRegion:region mipmapLevel:0];
    }
}

int imageNegative(WolframLibraryData libData, mint Argc, MArgument *Args, MArgument Res){
    
    logToFile("Entering imageNegative function");
    mint row, col;
    MImage image_in, image_out = 0;
    float *data_in, *data_out;
    WolframImageLibrary_Functions imgFuns = libData->imageLibraryFunctions;

    logToFile("Getting data from Mathematica");
    image_in = MArgument_getMImage(Args[0]);
    row = imgFuns->MImage_getRowCount(image_in);
    col = imgFuns->MImage_getColumnCount(image_in);
    data_in = imgFuns->MImage_getReal32Data(image_in);
    logToFile("Data obtained from Mathematica");

    logToFile("Initializing output variable");
    imgFuns->MImage_clone(image_in, &image_out);
    data_out = imgFuns->MImage_getReal32Data(image_out);

    // Send job to GPU
    logToFile("Transferring job to GPU");
    processImageNegative(data_in, row, col, data_out);

    // Return result to Mathematica
    MArgument_setMImage(Res, image_out);
    return LIBRARY_NO_ERROR;
}