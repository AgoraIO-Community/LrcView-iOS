//
//  TokenBuilder.m
//  AgoraEducation
//
//  Created by SRS on 2021/1/13.
//  Copyright © 2021 yangmoumou. All rights reserved.
//

#import "TokenBuilder.h"
#import "RtmTokenTool.h"
#import "RtcTokenTool.h"

#define NoNullString(x) ([x isKindOfClass:NSString.class] ? x : @"")
#define NoNullDictionary(x) ([x isKindOfClass:NSDictionary.class] ? x : @{})
#define NoNullArray(x) ([x isKindOfClass:NSArray.class] ? x : @[])

@implementation TokenBuilder


/// 生成rtm(006) token 用于本地快速演示使用， 我们建议你使用服务器生成token
+ (NSString *)buildRtmToken:(NSString *)appID
          appCertificate:(NSString *)appCertificate
                   userUuid:(NSString *)userUuid {
    return [RtmTokenTool token:appID
                appCertificate:appCertificate
                           uid:userUuid];
}

/// 生成rtm(007) token 用于本地快速演示使用， 我们建议你使用服务器生成token
+ (NSString *)buildRtmToken2:(NSString *)appID
           appCertificate:(NSString *)appCertificate
                    userUuid:(NSString *)userUuid {
    return [RtmTokenTool token2:appID
                 appCertificate:appCertificate
                            uid:userUuid];
}
/// 生成rtc(007) 
+ (NSString *)rtcToken2:(NSString *)appId
         appCertificate:(NSString *)appCertificate
                    uid:(int)uid
            channelName:(NSString *)channelName{
    return  [RtcTokenTool rtcToken2:appId
                     appCertificate:appCertificate
                                uid:uid
                        channelName:channelName];
}

+ (NSString *)buildToken:(NSString *)appID
          appCertificate:(NSString *)appCertificate
                userUuid:(NSString *)userUuid {
    return [RtmTokenTool token:appID
                appCertificate:appCertificate
                           uid:userUuid];
}

+ (NSString *)buildToken2:(NSString *)appID
           appCertificate:(NSString *)appCertificate
                 userUuid:(NSString *)userUuid {
    return [RtmTokenTool token2:appID
                 appCertificate:appCertificate
                            uid:userUuid];
}

@end
