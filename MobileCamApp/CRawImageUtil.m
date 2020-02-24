//
//  CRawImageUtil.m
//  ICatchPancamApp
//
//  Created by linux1 on 10/10/16.
//  Copyright © 2016 linux1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "CRawImageUtil.h"


@implementation CRawImageUtil

-(bool) initImage: (NSString*)imageName
{
    NSString* baseName  = [imageName stringByDeletingPathExtension];
    NSString* extension = [imageName pathExtension];
    
    imagePath = [[NSBundle mainBundle] pathForResource: baseName ofType: extension];
    NSLog(@"imagePath: %@", imagePath);
    
    UIImage* image = [UIImage imageNamed:imagePath];
    if (image == nil) {
        return false;
    }
    
    CGImageRef  imageRef = [image CGImage];
    
    imageWidth = (int)CGImageGetWidth(imageRef);
    imageHeight = (int)CGImageGetHeight(imageRef);
    
    // create bitmap context.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContexRef = CGBitmapContextCreate(NULL,
                                                     imageWidth,
                                                     imageHeight,
                                                     8,               /* bytes per component */
                                                     4 * imageWidth,  /* bytes per raw */
                                                     colorSpace,
                                                     kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    // draw image to bitmap context
    CGRect theRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextDrawImage(cgContexRef, theRect, imageRef);
    
    // copy data
    imageData = (Byte*)malloc(4 * imageWidth * imageHeight);
    memcpy(imageData, (Byte*)CGBitmapContextGetData(cgContexRef), 4 * imageWidth * imageHeight);
    
    // release bitmap context
    CGContextRelease(cgContexRef);
    
    // return raw image data
    return true;
}

- (BOOL)initImage1:(UIImage *)image
{
    CGImageRef  imageRef = [image CGImage];
    
    imageWidth = (int)CGImageGetWidth(imageRef);
    imageHeight = (int)CGImageGetHeight(imageRef);
    
    // create bitmap context.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContexRef = CGBitmapContextCreate(NULL,
                                                     imageWidth,
                                                     imageHeight,
                                                     8,               /* bytes per component */
                                                     4 * imageWidth,  /* bytes per raw */
                                                     colorSpace,
                                                     kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    // draw image to bitmap context
    CGRect theRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextDrawImage(cgContexRef, theRect, imageRef);
    
    // copy data
    imageData = (Byte*)malloc(4 * imageWidth * imageHeight);
    memcpy(imageData, (Byte*)CGBitmapContextGetData(cgContexRef), 4 * imageWidth * imageHeight);
    
    // release bitmap context
    CGContextRelease(cgContexRef);
    
    // return raw image data
    return YES;
}

- (bool) uninitImage
{
    if (imageData != NULL) {
        free(imageData);
        imageData = NULL;
    }
    
    return true;
}

- (Byte*) getImageData
{
    return imageData;
}

- (int)   getImageWidth
{
    return imageWidth;
}

- (int)   getImageHeight
{
    return imageHeight;
}

@end
