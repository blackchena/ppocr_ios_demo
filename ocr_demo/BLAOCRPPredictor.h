//
//  BLAOCRPPredictor.h
//  ocr_demo
//
//  Created by chensiyu on 2022/2/22.
//  Copyright © 2022 Li,Xiaoyang(SYS). All rights reserved.
//

#import<UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BLAOCRPPredictor : NSObject
+ (instancetype)defaultPredictor;
- (instancetype)initWithDetModel:(NSString *)detModel
                        recModel:(NSString *)recModel
                        clsModel:(NSString * _Nullable)clsModel;
- (void)inferImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
