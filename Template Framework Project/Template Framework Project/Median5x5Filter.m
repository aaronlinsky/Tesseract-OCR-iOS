//
//  Median5x5Filter.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 02.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "Median5x5Filter.h"

NSString *const kGPUImageMedian5x5FragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 uniform float texelWidth;
 uniform float texelHeight;

 varying vec2 textureCoordinate;
 varying vec2 leftTextureCoordinate;
 varying vec2 rightTextureCoordinate;
 
 varying vec2 topTextureCoordinate;
 varying vec2 topLeftTextureCoordinate;
 varying vec2 topRightTextureCoordinate;
 
 varying vec2 bottomTextureCoordinate;
 varying vec2 bottomLeftTextureCoordinate;
 varying vec2 bottomRightTextureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
#define s2(a, b)				temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)			s2(a, b); s2(a, c);
#define mx3(a, b, c)			s2(b, c); s2(a, c);
 
#define mnmx3(a, b, c)			mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)		s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)	s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges
 
#define t2(a, b)				s2(v[a], v[b]);
#define t24(a, b, c, d, e, f, g, h)			t2(a, b); t2(c, d); t2(e, f); t2(g, h);
#define t25(a, b, c, d, e, f, g, h, i, j)		t24(a, b, c, d, e, f, g, h); t2(i, j);

 void main()
 {
     vec3 v[25];
     
//     v[0] = texture2D(inputImageTexture, bottomLeftTextureCoordinate).rgb;
//     v[1] = texture2D(inputImageTexture, topRightTextureCoordinate).rgb;
//     v[2] = texture2D(inputImageTexture, topLeftTextureCoordinate).rgb;
//     v[3] = texture2D(inputImageTexture, bottomRightTextureCoordinate).rgb;
//     v[4] = texture2D(inputImageTexture, leftTextureCoordinate).rgb;
//     v[5] = texture2D(inputImageTexture, rightTextureCoordinate).rgb;
//     v[6] = texture2D(inputImageTexture, bottomTextureCoordinate).rgb;
//     v[7] = texture2D(inputImageTexture, topTextureCoordinate).rgb;
//     v[8] = texture2D(inputImageTexture, textureCoordinate).rgb;
     
//     vec3 temp;
//
//     mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
//     mnmx5(v[1], v[2], v[3], v[4], v[6]);
//     mnmx4(v[2], v[3], v[4], v[7]);
//     mnmx3(v[3], v[4], v[8]);
//     
//     
//     gl_FragColor = vec4(v[4], 1.0);

     for(int dX = -2; dX <= 2; ++dX) {
          for(int dY = -2; dY <= 2; ++dY) {
              vec2 offset = vec2(float(dX), float(dY)) * vec2(texelWidth, texelHeight);
              v[(dX+2) * 5 + (dY+2)] = texture2D(inputImageTexture, textureCoordinate + offset).rgb;
          }
     }

     vec3 temp;
     
     t25(0, 1,			3, 4,		2, 4,		2, 3,		6, 7);
     t25(5, 7,			5, 6,		9, 7,		1, 7,		1, 4);
     t25(12, 13,		11, 13,		11, 12,		15, 16,		14, 16);
     t25(14, 15,		18, 19,		17, 19,		17, 18,		21, 22);
     t25(20, 22,		20, 21,		23, 24,		2, 5,		3, 6);
     t25(0, 6,			0, 3,		4, 7,		1, 7,		1, 4);
     t25(11, 14,		8, 14,		8, 11,		12, 15,		9, 15);
     t25(9, 12,		13, 16,		10, 16,		10, 13,		20, 23);
     t25(17, 23,		17, 20,		21, 24,		18, 24,		18, 21);
     t25(19, 22,		8, 17,		9, 18,		0, 18,		0, 9);
     t25(10, 19,		1, 19,		1, 10,		11, 20,		2, 20);
     t25(2, 11,		12, 21,		3, 21,		3, 12,		13, 22);
     t25(4, 22,		4, 13,		14, 23,		5, 23,		5, 14);
     t25(15, 24,		6, 24,		6, 15,		7, 16,		7, 19);
     t25(3, 11,		5, 17,		11, 17,		9, 17,		4, 10);
     t25(6, 12,		7, 14,		4, 6,		4, 7,		12, 14);
     t25(10, 14,		6, 7,		10, 12,		6, 10,		6, 17);
     t25(12, 17,		7, 17,		7, 10,		12, 18,		7, 12);
     t24(10, 18,		12, 20,		10, 20,		10, 12);

     
     gl_FragColor = vec4(v[12], 1.0);
 }
);


@implementation Median5x5Filter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithImage:(UIImage*)image;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageMedian5x5FragmentShaderString]))
    {
        return nil;
    }
    
    hasOverriddenImageSizeFactor = NO;
//    self.texelWidth = self.texelHeight = 2;
    self.texelWidth = 2.0 / image.size.width;
    self.texelHeight = 2.0 / image.size.height;

    
    return self;
}

@end
