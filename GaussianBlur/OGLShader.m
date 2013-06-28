//
//  OGLShader.m
//
// Created by Zikomo Fields 
// Modified by Jimmy Lu on 1/24/12, 


#import "OGLShader.h"

#pragma mark - Private

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

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

@interface OGLShader()

@property (nonatomic, assign) CGSize size;

- (void)setupGL;
- (void)tearDownGL;
- (ShaderHelper)loadShaders:(NSString*)filename;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (GLuint)uiimageToGLTexture:(UIImage*)image;
- (UIImage*)glTextureToUIImageOfSize:(CGSize)size;
- (void)renderWithSize:(CGSize)size andTexture:(GLuint)textureHandle;

@end

#pragma mark - Implementation

@implementation OGLShader

- (id)init {
    self = [super init];
    if (self) {
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        UIApplication* app = [UIApplication sharedApplication];
        
        if (!app.isStatusBarHidden) {
            screenSize.height = screenSize.height - app.statusBarFrame.size.height;
        }
        
        self.size = screenSize;
        
        [self setupGL];
    }
    return self;
}

- (id)initWithSize:(CGSize)size 
       withHShader:(NSString*)horizontalShader 
        andVShader:(NSString*)verticalShader {
    
    self = [super init];
    if (self) {        
        self.size = size;
        self.horizontalShader = horizontalShader;
        self.verticalShader = verticalShader;
        [self setupGL];
    }
    return self;
}


- (void)createAndBindTextureToFrameBuffer:(GLuint)fbo:(GLuint)texture:(uint)width:(uint)height:(void*)data
{

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    NSLog(@"error %x %d %d",glGetError(),width, height);

    
    if (fbo == 0x123456) return;
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
}



- (void)setupGL {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.context = context;
    [context release];
    
    [EAGLContext setCurrentContext:self.context];
    _programHorz = [self loadShaders:@"horzBlurShader"];
    _programVert = [self loadShaders:@"vertBlurShader"];
    
    glDisable(GL_DEPTH_TEST);
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);

    glGenTextures(1, &_tex0);
    glGenFramebuffers(1, &_fbo0);
    glGenTextures(1, &_tex1);
    glGenFramebuffers(1, &_fbo1);
    
    [self createAndBindTextureToFrameBuffer:_fbo0 :_tex0 :self.size.width :self.size.height:NULL];
    [self createAndBindTextureToFrameBuffer:_fbo1 :_tex1 :self.size.width :self.size.height:NULL];

    
    GLenum status = glCheckFramebufferStatusOES(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Problem with OpenGL framebuffer after specifying color render buffer: %x", status);
    }
    

    glViewport(0, 0, self.size.width, self.size.height);
    int vPort[4];
    
    glGetIntegerv(GL_VIEWPORT, vPort);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    
    glOrthof(0, vPort[2], 0, vPort[3], 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();    
    _isInitialized = YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file 
                                                  encoding:NSUTF8StringEncoding 
                                                     error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if DEBUG
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

- (BOOL)linkProgram:(GLuint)prog {
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

- (ShaderHelper)loadShaders:(NSString*)filename {
    ShaderHelper rtnHelper;
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
        }
        if (fragShader) {
            glDeleteShader(fragShader);
        }
        if (_program) {
            glDeleteProgram(_program);
        }
        
        return rtnHelper;
    }
    
    rtnHelper.uniforms[UNIFORM_IMAGE] = glGetUniformLocation(_program, "image");
    rtnHelper.uniforms[UNIFORM_HEIGHT] = glGetUniformLocation(_program, "height");
    rtnHelper.uniforms[UNIFORM_WIDTH] = glGetUniformLocation(_program, "width");
    rtnHelper.uniforms[UNIFORM_PASSES] = glGetUniformLocation(_program, "passes");
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

- (UIImage*)gaussianBlur:(UIImage*)image {
    NSLog(@"image has size %f %f ", image.size.width, image.size.height);
    if (!CGSizeEqualToSize(image.size, self.size)) {
        self.size = image.size;
        [self tearDownGL];
        [self setupGL];
    }
#ifdef DEBUG
    CFTimeInterval start = CFAbsoluteTimeGetCurrent();
#endif    
    GLuint textureHandle = [self uiimageToGLTexture:image];
    [self renderWithSize:image.size andTexture:textureHandle];
    UIImage* newImage = [[self glTextureToUIImageOfSize:image.size] autorelease]; 
#ifdef DEBUG
    CFTimeInterval finish = CFAbsoluteTimeGetCurrent();
    float deltaTimeInSeconds = finish - start;    
    NSLog(@"Ellapsed Time %f",deltaTimeInSeconds);
#endif
    return newImage;
}

- (UIImage*)gaussianBlur:(UIImage *)image nTimes:(NSInteger)times {
    if (times <= 0) {
        return image;
    }
    
    if (times == 1) {
        return [self gaussianBlur:image];
    }
    
    if (!CGSizeEqualToSize(image.size, self.size)) {
        self.size = image.size;
        [self tearDownGL];
        [self setupGL];
    }
    
    [image retain];
    
    NSInteger successiveBlurs = 0;
    UIImage* blurredImage = nil;
    // since we are repeatedly creating UIImage objects, we need to be aggressive
    // in releasing memory.  Using ARC or simply using autorelease will kill any
    // app that calls this method with times > a few times
    while (successiveBlurs <= times ) {
        GLuint textureHandle = [self uiimageToGLTexture:image];
        [self renderWithSize:image.size andTexture:textureHandle];
        blurredImage = [self glTextureToUIImageOfSize:image.size];
        [image release];
        image = blurredImage;
        successiveBlurs++;
    }
    return [image autorelease];
}

-(GLuint)uiimageToGLTexture:(UIImage*)image {
    uint width = image.size.width, height = image.size.height;
    uint imageSize = width * height * 4;
    unsigned char* textureData = (unsigned char*)malloc(imageSize);
    struct CGContext* textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image.CGImage);
    CGContextRelease(textureContext);
    GLuint textureHandle;
    glGenTextures(1, &textureHandle);
    [self createAndBindTextureToFrameBuffer:0x123456 :textureHandle :width :height:textureData];

    free(textureData);
    return textureHandle;
}

-(UIImage*)glTextureToUIImageOfSize:(CGSize)size {
    uint imageSize = size.width*size.height*4;
    unsigned char* buffer = malloc(imageSize);
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);    
    glReadPixels(0,0,size.width,size.height,GL_RGBA,GL_UNSIGNED_BYTE, buffer);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, (size.width * size.height * 4), NULL);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(size.width,size.height,8,32,size.width*4,colorSpace,
                                    kCGBitmapByteOrderDefault,provider,NULL, true, kCGRenderingIntentDefault);
    uint32_t* pixels = (uint32_t *)malloc(imageSize);
    
    CGContextRef context = CGBitmapContextCreate(pixels, 
                                                 size.width, 
                                                 size.height, 
                                                 8, 
                                                 size.width*4, 
                                                 CGImageGetColorSpace(iref),
                                                 kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), iref);   
    CGImageRef outputRef = CGBitmapContextCreateImage(context);
    
    UIImage* newImage = [[UIImage alloc] initWithCGImage:outputRef];
    
    free(buffer);
    free(pixels);
    CGImageRelease(outputRef);
    CGContextRelease(context);
    CGImageRelease(iref);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    return newImage;
}

- (void)renderWithSize:(CGSize)size andTexture:(GLuint)textureHandle {
    glClear(GL_COLOR_BUFFER_BIT);    
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);  

    
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo0);   
    glActiveTexture(GL_TEXTURE0);
    glUniform1f(_programVert.uniforms[UNIFORM_IMAGE], 0);

    glBindTexture(GL_TEXTURE_2D, textureHandle);
    glUseProgram(_programVert.program);
    glUniform1f(_programVert.uniforms[UNIFORM_HEIGHT], self.size.height);
    glUniform1f(_programVert.uniforms[UNIFORM_WIDTH], self.size.width);
    glDrawArrays(GL_TRIANGLE_STRIP,0,4);
    for (int i=0; i < 5; i++)
    {
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo1);   
        glActiveTexture(GL_TEXTURE0);
        glUniform1f(_programHorz.uniforms[UNIFORM_IMAGE], 0);

        glBindTexture(GL_TEXTURE_2D, _tex0);
        glUseProgram(_programHorz.program);
        glUniform1f(_programHorz.uniforms[UNIFORM_HEIGHT], self.size.height);
        glUniform1f(_programHorz.uniforms[UNIFORM_WIDTH], self.size.width);
    
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
    
        glBindFramebuffer(GL_FRAMEBUFFER, _fbo0);   
        glActiveTexture(GL_TEXTURE0);
        glUniform1f(_programHorz.uniforms[UNIFORM_IMAGE], 0);
    
        glBindTexture(GL_TEXTURE_2D, _tex1);
        glUseProgram(_programVert.program);
        glUniform1f(_programVert.uniforms[UNIFORM_HEIGHT], self.size.height);
        glUniform1f(_programVert.uniforms[UNIFORM_WIDTH], self.size.width);
        glDrawArrays(GL_TRIANGLE_STRIP,0,4);
    }
    glDeleteTextures(1, &textureHandle);
    
}

#pragma mark Memory Management

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
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
    _isInitialized = NO;
}

- (void)dealloc {
    [self tearDownGL];
    
    self.context = nil;
    self.effect = nil;
    self.horizontalShader = nil;
    self.verticalShader = nil;
    
    [super dealloc];
}

@synthesize context;
@synthesize effect;
@synthesize horizontalShader;
@synthesize verticalShader;
@synthesize size = _size;

@end
