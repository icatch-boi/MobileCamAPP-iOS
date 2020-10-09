//
//  Video.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//  Copyright 2010 www.codza.com. All rights reserved.
//

#import "VideoFrameExtractor.h"
#import "Tool.h"

@interface VideoFrameExtractor ()
@property (nonatomic) UIImage *img;
-(void)convertFrameToRGB;
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height;
//-(void)savePicture:(AVPicture)pFrame width:(int)width height:(int)height index:(int)iFrame;
-(void)setupScaler;
//@property (nonatomic) UIImage *currentImage;
@end

@implementation VideoFrameExtractor

@synthesize outputWidth, outputHeight;

-(void)setOutputWidth:(int)newValue {
  TRACE();
	if (outputWidth == newValue) return;
	outputWidth = newValue;
	[self setupScaler];
}

-(void)setOutputHeight:(int)newValue {
  TRACE();
	if (outputHeight == newValue) return;
	outputHeight = newValue;
	[self setupScaler];
}

-(UIImage *)currentImage {
	if (!pFrame->data[0]) return nil;
	[self convertFrameToRGB];
    self.img = [self imageFromAVPicture:picture width:outputWidth height:outputHeight];
    return _img;
}

-(double)duration {
	return (double)pFormatCtx->duration / AV_TIME_BASE;
}

-(int)sourceWidth {
	return pCodecCtx->width;
}

-(int)sourceHeight {
	return pCodecCtx->height;
}

-(id)init {
  
  if (!(self=[super init])) return nil;
  
  AVCodec* pCodec;
  
  // Register all formats and codecs
  av_register_all();
  
  // Find the decoder for the video stream
  pCodec = avcodec_find_decoder( AV_CODEC_ID_H264 );
  // Get a pointer to the codec context for the video stream
  pCodecCtx = avcodec_alloc_context3( pCodec );
  // Open codec
  avcodec_open2(pCodecCtx, pCodec, nil);
  
  
  
  pCodecCtx->width = 640;
  pCodecCtx->height = 360;
  pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
  
  // Allocate video frame
//  pFrame=avcodec_alloc_frame();
    pFrame=av_frame_alloc();
  
  outputWidth = pCodecCtx->width;
  outputHeight = pCodecCtx->height;
  
  return self;
}


-(id)initWithSize:(int)width andHeight:(int)height
{
  if (!(self=[super init])) return nil;
  
  AVCodec* pCodec;
  
  // Register all formats and codecs
  av_register_all();
  
  // Find the decoder for the video stream
  pCodec = avcodec_find_decoder( AV_CODEC_ID_H264 );
  // Get a pointer to the codec context for the video stream
  pCodecCtx = avcodec_alloc_context3( pCodec );
  // Open codec
  avcodec_open2(pCodecCtx, pCodec, nil);
  
  pCodecCtx->width = width;
  pCodecCtx->height = height;
  pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
  
  // Allocate video frame
//  pFrame=avcodec_alloc_frame();
    pFrame=av_frame_alloc();
  
  outputWidth = pCodecCtx->width;
  self.outputHeight = pCodecCtx->height;
  
  return self;
}

-(id)initWithVideo:(NSString *)moviePath {
	if (!(self=[super init])) return nil;
    
    /*av_register_all();
    AVPacket packet;
    av_new_packet( &packet, 0x100000 );
    AVCodec* codec;
    codec = avcodec_find_decoder( AV_CODEC_ID_H264 );
    //AVCodecContext* ccontext = avcodec_alloc_context3( codec );
    pCodecCtx = avcodec_alloc_context3( codec );
    avcodec_get_context_defaults3( pCodecCtx, codec );
    
    avcodec_open2( pCodecCtx, codec, nil );
    
    int check = 0;
    //AVFrame* pFrame = avcodec_alloc_frame();
//    pFrame = avcodec_alloc_frame();
    pFrame=av_frame_alloc();
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.h264" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile: path ];
    Byte* bytes = ( Byte* )[data bytes];
    packet.data = bytes;
    packet.size = data.length;
    avcodec_decode_video2( pCodecCtx, pFrame, &check, &packet );
    
    outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
    
    return self;*/
  
  
  
 
    AVCodec         *pCodec;
		
    // Register all formats and codecs
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
	
    // Open video file
	// av_open_input_file(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding],NULL, 0,NULL)!=0
	// avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding],NULL, NULL)!=0
    int ret = avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], nil, nil);
    char buf[1024];
    if(ret != 0) {
        NSLog(@"------> %d", ret);
        av_strerror(ret, buf, sizeof(buf));
        printf("====> %s", buf);
        goto initError; // Couldn't open file
    }

//	if(av_open_input_stream(&pFormatCtx, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], nil, 0, nil) != 0)
//        goto initError; // Couldn't open file
	
    // Retrieve stream information
//    if(av_find_stream_info(pFormatCtx)<0)
	if(avformat_find_stream_info(pFormatCtx, nil) < 0)
        goto initError; // Couldn't find stream information
		
    // Find the first video stream
    videoStream=-1;
    for(int i=0; i<pFormatCtx->nb_streams; i++)
        //if(pFormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_VIDEO)
		if(pFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO)
        {
            videoStream=i;
            break;
        }
    if(videoStream==-1)
        goto initError; // Didn't find a video stream
	
    // Get a pointer to the codec context for the video stream
    pCodecCtx=pFormatCtx->streams[videoStream]->codec;
		
    // Find the decoder for the video stream
    pCodec=avcodec_find_decoder(pCodecCtx->codec_id);
    if(pCodec==NULL)
        goto initError; // Codec not found
	
    // Open codec
//    if(avcodec_open(pCodecCtx, pCodec)<0)
	if(avcodec_open2(pCodecCtx, pCodec, nil))
        goto initError; // Could not open codec
	
    // Allocate video frame
//    pFrame=avcodec_alloc_frame();
    pFrame=av_frame_alloc();
			
	outputWidth = pCodecCtx->width;
	self.outputHeight = pCodecCtx->height;
			
	return self;
	
initError:
	return nil;
}


-(void)setupScaler {

  TRACE();
	// Release old picture and scaler
	avpicture_free(&picture);
	sws_freeContext(img_convert_ctx);	
	
	// Allocate RGB picture
	avpicture_alloc(&picture, AV_PIX_FMT_RGB24, outputWidth, outputHeight);
	
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	img_convert_ctx = sws_getContext(pCodecCtx->width, 
									 pCodecCtx->height,
									 pCodecCtx->pix_fmt,
									 outputWidth, 
									 outputHeight,
									 AV_PIX_FMT_RGB24,
									 sws_flags, NULL, NULL, NULL);
	
}

-(void)seekTime:(double)seconds {
	AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(pFormatCtx, videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(pCodecCtx);
}

-(void)dealloc {
	// Free scaler
	sws_freeContext(img_convert_ctx);	

	// Free RGB picture
	avpicture_free(&picture);
	
    // Free the YUV frame
//    av_free(pFrame);
    av_frame_free(&(pFrame));
	
    // Close the codec
    if (pCodecCtx) avcodec_close(pCodecCtx);
	
    // Close the video file
//    if (pFormatCtx) av_close_input_file(pFormatCtx);
	if (pFormatCtx) {
		avformat_close_input(&pFormatCtx);
	}
}

-(BOOL)stepFrame {
	AVPacket packet;
    int frameFinished=0;

    while(!frameFinished && av_read_frame(pFormatCtx, &packet)>=0) {
        // Is this a packet from the video stream?
        if(packet.stream_index==videoStream) {
            // Decode video frame
            avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
        }
		
        // Free the packet that was allocated by av_read_frame
        av_free_packet(&packet);
	}
	return frameFinished!=0;
}

-(BOOL)fillData:(uint8_t *)buf size:(int)size {
  int frameFinished = 0;
  AVPacket packet;
  av_new_packet(&packet, size);
  memcpy(packet.data, buf, size);
  

  NSMutableString *result = [[NSMutableString alloc] init];
  NSDate *beforeDecodeDate = [NSDate date];
  
  avcodec_decode_video2(pCodecCtx, pFrame, &frameFinished, &packet);
  
  NSDate *afterDecodeDate = [NSDate date];
  NSTimeInterval timeIntervalSinceNow = [afterDecodeDate timeIntervalSinceDate:beforeDecodeDate];
  NSDateFormatter *format = [[NSDateFormatter alloc] init];
  [format setDateFormat:@".S"];
  NSString *timeIntervalStr = [NSString stringWithFormat:@"%.f", timeIntervalSinceNow*1000];
  [result appendString:timeIntervalStr];
  //AppLog(@"decode time : %@ms", result);
  
  av_free_packet(&packet);
  
  return YES;
}

-(void)convertFrameToRGB {	
	sws_scale (img_convert_ctx, pFrame->data, pFrame->linesize,
			   0, pCodecCtx->height,
			   picture.data, picture.linesize);	
}

-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
//	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, 
									   height, 
									   8, 
									   24, 
									   pict.linesize[0], 
									   colorSpace, 
									   bitmapInfo, 
									   provider, 
									   NULL, 
									   NO, 
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
  
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}

-(void)savePPMPicture:(AVPicture)pict width:(int)width height:(int)height index:(int)iFrame {
    FILE *pFile;
	NSString *fileName;
    int  y;
	
	fileName = [Tool documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    // Open file
    NSLog(@"write image file: %@",fileName);
    pFile=fopen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    if(pFile==NULL)
        return;
	
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
	
    // Write pixel data
    for(y=0; y<height; y++)
        fwrite(pict.data[0]+y*pict.linesize[0], 1, width*3, pFile);
	
    // Close file
    fclose(pFile);
}

@end
