//
//  DemoViewController.m
//  Testing
//
//  Created by Zikomo Fields on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "imageEffects.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Uniform index.
enum
{
    UNIFORM_IMAGE,
    UNIFORM_HEIGHT,
	UNIFORM_WIDTH,
    UNIFORM_PASSES,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];



// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};


static const GLfloat squareVertices[] = {
    1.0f, 1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    -1.0f,  -1.0f,
};

static const GLfloat textureVertices[] = {
    1.0f, 1.0f,
    1.0f, 0.0f,
    0.0f,  1.0f,
    0.0f,  0.0f,
};

struct ShaderHelper
{
    GLuint uniforms[NUM_UNIFORMS];
    GLuint program;
    bool status;
};

@interface imageEffects () {
    struct ShaderHelper _programHorz;
    struct ShaderHelper _programVert;
    
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _textureHandleA 
    BOOL _isInitialized;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)initialize:(uint)width:(uint)height;
- (void)setupGL:(uint)width:(uint)height;
- (void)tearDownGL;
- (void)render;
- (GLuint)uiimageToGLTexture:(UIImage*)image;
- (UIImage*)glTextureToUIImage:(uint)width:(uint)height;
- (void)setupFrameBuffers:(uint)width:(uint)height;
- (UIImage*)gaussianBlur:(UIImage*)image;
- (struct ShaderHelper)loadShaders:(NSString*)filename;
- (BOOL)loadVertShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation imageEffects

@synthesize context = _context;
@synthesize effect = _effect;;

- (void)dealloc
{
    [_context release];
    [_effect release];
    [super dealloc];
}


-(void)initialize:(uint)width:(uint)height
{
    self.context = [[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2] autorelease];
    
    if (!self.context) 
    {
        NSLog(@"Failed to create ES context");
    }
    
    [self setupGL:width:height];
    _isInitialized = TRUE;
}

- (void)setupGL:(uint)width:(uint)height
{
    [EAGLContext setCurrentContext:self.context];    
    _programHorz = [self loadShaders:@"horzBlurShader"];
    _programVert = [self loadShaders:@"vertBlurShader"];
                
    glDisable(GL_DEPTH_TEST);

	glGenTextures(1, &_textureHandleA);
	glBindTexture(GL_TEXTURE_2D, _textureHandleA);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); 
    
  0;
 GLuint    glGenFramebuffersOES(1, &_fboA);
   glBindFramebufferOES(GL_FRAMEBUFFER_OES, _fboA);
   glFr  renderBuffer = 0;
    glGenRenderbuffersOES(1, &renderBuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderBuffer);
    glRenderbufferStorageOES(GL_RENDERBUFFER_OES,
                             GL_RGBA8_OES,
                             width,
                             height);
    
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES,
                                 GL_COLOR_ATTACHMENT0_OES,
                                 GL_RENDERBUFFER_OES,
                                 renderBuffer);
    
    GLenum status = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES);
    if (status != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"Problem with OpenGL framebuffer after specifying color render buffer: %x", status);
    }
    

    glViewport(0, 0, width, height);
    int vPort[4];
    
    glGetIntegerv(GL_VIEWPORT, vPort);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    
    glOrthof(0, vPort[2], 0, vPort[3], 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    glUniform1i(uniforms[UNIFORM_IMAGE], 0);	
    
	// Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    glUseProgram(_programHorz.program);
    glUseProgram(_programVert.program);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
    if (_programHorz.status) 
    {
        glDeleteProgram(_programHorz.program);
        _programHorz.status = false;
        _programHorz.program = 0;
        
    }
    
    if (_programVert.status) 
    {
        glDeleteProgram(_programVert.program);
        _programVert.status = false;
        _programHorz.program = 0;
    }
    _isInitialized = FALSE;
}


-(void)render:(uint)width:(uint)height:(GLuint)textureHandle
{

    //clear fr;me to known diagnostic color
    glClearColor(0.2, 0.5, 0.8, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    //set shader uniforms
    glUniform1f(_programHorz.uniforms[UNIFORM_HEIGHT], height);
    glUniform1f(_programHorz.uniforms[UNIFORM_WIDTH], width);
    glUniform1f(_programVert.uniforms[UNIFORM_HEIGHT], height);
    glUniform1f(_programVert.uniforms[UNIFORM_WIDTH], width);
    //set active texture
    //glActiveTextu(GL_TEXTURE0);
    //draw full screen quad
    glUseProgra
    _TRIANGLE_STRIP, 0, 4);
    glUseProgr-(UIImage*)gaussianBlur:(UIImage*)image
{
    if (!_isInitialized) 
    {
        [self initialize:image.size.width:image.size.height];
    }
#ifdef DEBUG
    CFTimeInterval start = CFAbsoluteTimeGetCurrent();
#endif    
    GLuint textureHandle = [self uiimageToGLTexture:image];
    [self render:image.size.width:image.size.height:textureHandle];
    UIImage* newImage = [self glTextureToUIImage: image.size.width: image.size.height]; 
#ifdef DEBUG
    CFTimeInterval finish = CFAbsoluteTimeGetCurrent();
    float deltaTimeInSeconds = finish - start;    
    NSLog(@"Ellapsed Time %f",deltaTimeInSeconds);
#endif
    return newImage;
}

-(GLuint)uiimageToGLTexture:(UIImage*)image
{    
    uint width = image.size.width, height = image.size.height;
    uint imageSize = width * height * 4;
    unsigned char* textureData = (unsigned char*)malloc(imageSize);
    struct CGContext* textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image.CGImage);
    CGContextRelease(textureCofboOuglBindTexture(GLage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textuLINEA;
    //memset(glBindTexture(GL_TEXTURE_2D, _textureHandle);ee(textureData);
   _textureHandleA texture;
}

-(UIImage*)glTextureToUIImage:(uint)width:(uint)height
{
    uint imageSize = width*height*4;
    unsigned char* buffer = malloc(imagfboOut);
    glPixelStorei(GL_PACK_ALIGNMENT, 4);    
    glReadPixels(0,0,width,height,GL_RGBA,GL_UNSIGNED_BYTE, buffer);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, (width * height * 4), NULL);
    CGImageRef iref = CGImageCreate(width,height,8,32,width*4,CGColorSpaceCreateDeviceRGB(),
                                    kCGBitmapByteOrderDefault,provider,NULL, true, kCGRenderingIntentDefault);
    uint32_t* pixels = (uint32_t *)malloc(imageSize);
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width*4, CGImageGetColorSpace(iref),
                                                 kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, width, height), iref);   
    CGImageRef outputRef = CGBitmapContextCreateImage(context);
    UIImage* newImage = [[UIImage alloc] initWithCGImage:outputRef];
    free(buffe//r);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    return newImage;
}

-(void)setupFrameBuffers:(uint)width:(uint)height
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    GLuint colorRenderbuffer;
    glGenRenderbuffers(1, &colorRenderbuffer);
    //glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, width, height);
    //[self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    GLuint depthRenderbuffer;
    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    GLuint positionRenderTexture;
	glGenTextures(1, &positionRenderTexture);
    glBindTexture(GL_TEXTURE_2D, positionRenderTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
    //	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	//GL_NEAREST_MIPMAP_NEAREST
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    //    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FBO_WIDTH, FBO_HEIGHT, 0, GL_RGBA, GL_FLOAT, 0);
    
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, positionRenderTexture, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE) 
    {
        status = glGetError();
        NSLog(@"failed to make complete framebuffer object %x", status);
    }
}



#pragma mark -  OpenGL ES 2 shader compilation

- (struct ShaderHelper)loadShaders:(NSString*)filename
{
    struct ShaderHelper rtnHelper;
    rtnHelper.status = false;
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    GLuint _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:filename ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return rtnHelper;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:filename ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return rtnHelper;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return rtnHelper;
    }
    
    rtnHelper.uniforms[UNIFORM_IMAGE] = glGetUniformLocation(_program, "image");
    rtnHelper.uniforms[UNIFORM_HEIGHT] = glGetUniformLocation(_program, "height");
    rtnHelper.uniforms[UNIFORM_WIDTH] = glGetUniformLocation(_program, "width");
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    rtnHelper.status = true;
    rtnHelper.program = _program;
    
    return rtnHelper;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
