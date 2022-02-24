//
//  BLAOCRPPredictor.m
//  ocr_demo
//
//  Created by chensiyu on 2022/2/22.
//  Copyright © 2022 Li,Xiaoyang(SYS). All rights reserved.
//

#import "pdocr/ocr_ppredictor.h"
#import <opencv2/imgcodecs/ios.h>
#import "BLAOCRPPredictor.h"
#include "include/paddle_api.h"
#include "pdocr/preprocess.h"
#include "common.h"

cv::Mat resize_img(const cv::Mat &img, int max_size_len, float *ratio_h, float *ratio_w) {
    int w = img.cols;
    int h = img.rows;

    float ratio = 1.f;
    int max_wh = w >= h ? w : h;
    if (max_wh > max_size_len) {
        if (h > w) {
            ratio = float(max_size_len) / float(h);
        } else {
            ratio = float(max_size_len) / float(w);
        }
    }

    int resize_h = int(float(h) * ratio);
    int resize_w = int(float(w) * ratio);
    if (resize_h % 32 == 0)
        resize_h = resize_h;
    else if (resize_h / 32 < 1)
        resize_h = 32;
    else
        resize_h = (resize_h / 32 - 1) * 32;

    if (resize_w % 32 == 0)
        resize_w = resize_w;
    else if (resize_w / 32 < 1)
        resize_w = 32;
    else
        resize_w = (resize_w / 32 - 1) * 32;

    cv::Mat resize_img;
    cv::resize(img, resize_img, cv::Size(resize_w, resize_h));

    *ratio_h = float(resize_h) / float(h);
    *ratio_w = float(resize_w) / float(w);
    return resize_img;
}


@interface BLAOCRPPredictor ()

@property (nonatomic, assign) ppredictor::OCR_PPredictor *predictor;

@end

@implementation BLAOCRPPredictor

+ (instancetype)defaultPredictor {
    BLAOCRPPredictor *predictor = [[self alloc] initWithDetModel:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", @"ch_ppocr_mobile_v2_det_opt"] ofType:@"nb"] recModel:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", @"ch_ppocr_mobile_v2_rec_opt"] ofType:@"nb"] clsModel:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", @"ch_ppocr_mobile_v2_cls_opt"] ofType:@"nb"]];
    return predictor;
}

- (instancetype)initWithDetModel:(NSString *)detModel
                        recModel:(NSString *)recModel
                        clsModel:(NSString *)clsModel {
    self = [super init];
    if (self) {
        ppredictor::OCR_Config config;
        self->_predictor = new ppredictor::OCR_PPredictor(config);
        self->_predictor->init_from_file(std::string([detModel UTF8String]), std::string([recModel UTF8String]), std::string([clsModel UTF8String]));
    }
    return self;
}

- (void)inferImage:(UIImage *)image {
//    [self imagePixel:image];
    //preProcess
    cv::Mat matImg;
    UIImageToMat(image, matImg);
    
    cv::Mat tmpMatImg;
    cv::cvtColor(matImg, tmpMatImg, cv::COLOR_RGB2BGR);
    
    int max_side_len = 960;
    float ratio_h;
    float ratio_w;
    tmpMatImg = resize_img(tmpMatImg, max_side_len, &ratio_h, &ratio_w);
    
    cv::Mat floatMatImg;
    tmpMatImg.convertTo(floatMatImg, CV_32FC3, 1.0 / 255.f);
    
    float *imgData = reinterpret_cast<float *>(floatMatImg.data);
    int channels = 3;
    int width = floatMatImg.cols;
    int height = floatMatImg.rows;
    int inputLength = channels * width * height;
    float *inputData = new float[inputLength];
    neon_mean_scale(imgData, inputData, width * height, {0.485f, 0.456f, 0.406f}, {1/0.229f, 1/0.224f, 1/0.225f});
    std::vector<int64_t> dims = {1, 3, height, width};
    //测试查看cropImg
//    std::vector<cv::Mat> ocr_results = self->_predictor->det_crop_imgs(dims, inputData, inputLength, NET_OCR, matImg);
//    for (auto bp = ocr_results.crbegin(); bp != ocr_results.crend(); ++bp) {
//      const cv::Mat &matImg = *bp;
//        UIImage *uiimage = MatToUIImage(matImg);
//        NSLog(@"test uiimage =%@", uiimage);
//    }
    self->_predictor->infer_ocr(dims, inputData, inputLength, NET_OCR, matImg);
    std::vector<ppredictor::OCRPredictResult> result = self->_predictor->infer_ocr(dims, inputData, inputLength, NET_OCR, matImg);
}

- (void) imagePixel:(UIImage *)image
{

    struct pixel {
        unsigned char r, g, b, a;
    };


    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGImageRef imageRef = image.CGImage;

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    struct pixel *pixels = (struct pixel *) calloc(1, sizeof(struct pixel) * width * height);


    size_t bytesPerComponent = 8;
    size_t bytesPerRow = width * sizeof(struct pixel);

    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bytesPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    unsigned long numberOfPixels = width * height;

    if (context != NULL) {
        for (unsigned i = 0; i < numberOfPixels; i++) {
            //you can add code here
            NSLog(@"r = %d", pixels[i].r);
            NSLog(@"g = %d", pixels[i].g);
            NSLog(@"b = %d", pixels[i].b);
        }


        free(pixels);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpace);

}

@end
