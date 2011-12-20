//
//  ImageViewGridLayer.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@class ACDocument;

@interface ImageViewGridLayer : CALayer {
	IKImageView *owner;
	ACDocument *document;
	int rows;
	int cols;
	CGColorRef green;
    CGColorRef blue;
    CGColorRef red;
	CGColorRef gray;
}
@property (retain) IKImageView *owner;
@property (retain) ACDocument *document;
@property (assign) int rows;
@property (assign) int cols;

@end
