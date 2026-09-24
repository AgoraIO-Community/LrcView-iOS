//
//  RtcTokenTool.h
//  AgoraEducation
//
//  Created by Jerry on 2019/10/11.
//  Copyright © 2019 Jerry. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface RtmTokenTool : NSObject

+ (NSString *)token:(NSString *)appId
     appCertificate:(NSString *)appCertificate
                uid:(NSString *)uid;


+ (NSString *)token2:(NSString *)appId
      appCertificate:(NSString *)appCertificate
                 uid:(NSString *)uid;

@end

