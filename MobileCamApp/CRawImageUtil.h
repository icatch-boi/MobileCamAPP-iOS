//
//  Header.h
//  ICatchPancamApp
//
//  Created by linux1 on 10/10/16.
//  Copyright © 2016 linux1. All rights reserved.
//

#ifndef CRawImageUtil_h
#define CRawImageUtil_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CRawImageUtil : NSObject
{
    NSString*   imagePath;
    
    Byte*       imageData;
    int         imageWidth;
    int         imageHeight;
}

- (bool)  initImage : (NSString*)imageName;
- (bool)  uninitImage;

- (BOOL)initImage1:(UIImage *)image;

- (Byte*) getImageData;
- (int)   getImageWidth;
- (int)   getImageHeight;

@end

#endif /* CRawImageUtil_h */
