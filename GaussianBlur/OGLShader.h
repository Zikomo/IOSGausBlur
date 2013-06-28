//
//  OGLShader.h
//  Nomic
//
//  Created by Jimmy Lu on 1/24/12, 
//  ported from code by Zikomo Fields
//
//  Copyright (c) 2012 Nomic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

enum {
    UNIFORM_IMAGE,
    UNIFORM_HEIGHT,
	UNIFORM_WIDTH,
    UNIFORM_PASSES,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};

enum {
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

GLint uniforms[NUM_UNIFORMS];

struct _ShaderHelper {
    GLuint uniforms[NUM_UNIFORMS];
    GLuint program;
    bool status;
};
typedef struct _ShaderHelper ShaderHelper; 

// interface for an OGLShader object.
@interface OGLShader : NSObject {
    ShaderHelper _programHorz;
    ShaderHelper _programVert;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _tex0, _tex1;
    GLuint _fbo0, _fbo1, _fbo2;
    
    CGSize _size;
    
    BOOL _isInitialized;
}

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, retain) GLKBaseEffect *effect;
@property (nonatomic, copy) NSString* horizontalShader;
@property (nonatomic, copy) NSString* verticalShader;

- (id)initWithSize:(CGSize)size 
       withHShader:(NSString*)horizontalShader 
        andVShader:(NSString*)verticalShader;

- (UIImage*)gaussianBlur:(UIImage*)image;
- (UIImage*)gaussianBlur:(UIImage *)image nTimes:(NSInteger)times;

@end
