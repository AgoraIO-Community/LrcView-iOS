//
//  RtcTokenTool.h
//  RTMTokenBuilder
//
//  Created by ZYP on 2023/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RtcTokenTool : NSObject
+ (NSString *)rtcToken2:(NSString *)appId
      appCertificate:(NSString *)appCertificate
                 uid:(int)uid
            channelName:(NSString *)channelName;
@end

NS_ASSUME_NONNULL_END
