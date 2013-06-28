//
//  Shader.fsh
//  Testing
//
//  Created by Zikomo Fields on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

varying highp vec2 textureCoordinate;

uniform sampler2D image;
uniform mediump float width;
uniform mediump float height;
uniform mediump int passes;
 
void main()
{
    //gl_FragColor = texture2D( image, textureCoordinate);
    //gl_FragColor += vec4(width/height,0,0,0);
/*    for (mediump int i=0; i<passes; i++) 
    {    
        gl_FragColor = (texture2D( image,  textureCoordinate )) * 0.2270270270
        +(texture2D( image, textureCoordinate+vec2(0.0, 1.3846153846)/height )) * 0.3162162162
        +(texture2D( image, textureCoordinate-vec2(0.0, 1.3846153846)/height )) * 0.3162162162
        +(texture2D( image, textureCoordinate+vec2(0.0, 3.2307692308)/height )) * 0.0702702703
        +(texture2D( image, textureCoordinate-vec2(0.0, 3.2307692308)/height )) * 0.0702702703;
    }*/
    //gl_FragColor = texture2D( image, textureCoordinate);

    gl_FragColor = (texture2D( image,  textureCoordinate )) * 0.2270270270
    +(texture2D( image, textureCoordinate+vec2(0.0, 1.3846153846)/height )) * 0.3162162162
    +(texture2D( image, textureCoordinate-vec2(0.0, 1.3846153846)/height )) * 0.3162162162
    +(texture2D( image, textureCoordinate+vec2(0.0, 3.2307692308)/height )) * 0.0702702703
    +(texture2D( image, textureCoordinate-vec2(0.0, 3.2307692308)/height )) * 0.0702702703;
    
    
}
