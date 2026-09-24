//
//  TokenBuilder.h
//
//
//  Created by ZYP on 2021/1/13.
//  Copyright © 2021 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TokenBuilder : NSObject
/// 生成rtm(006) token 用于本地快速演示使用， 我们建议你使用服务器生成token
+ (NSString *)buildRtmToken:(NSString *)appID
             appCertificate:(NSString *)appCertificate
                   userUuid:(NSString *)userUuid;

/// 生成rtm(007) token 用于本地快速演示使用， 我们建议你使用服务器生成token
+ (NSString *)buildRtmToken2:(NSString *)appID
              appCertificate:(NSString *)appCertificate
                    userUuid:(NSString *)userUuid;

/// 生成rtc(007)
+ (NSString *)rtcToken2:(NSString *)appId
         appCertificate:(NSString *)appCertificate
                    uid:(int)uid
            channelName:(NSString *)channelName;


/// 生成rtm token 用于本地快速演示使用， 我们建议你使用服务器生成token( buildToken:success:failure:)
+ (NSString *)buildToken:(NSString *)appID
          appCertificate:(NSString *)appCertificate
                userUuid:(NSString *)userUuid __deprecated_msg("This method is deprecated. Use buildRtmToken instead.");

+ (NSString *)buildToken2:(NSString *)appID
           appCertificate:(NSString *)appCertificate
                 userUuid:(NSString *)userUuid __deprecated_msg("This method is deprecated. Use buildRtmToken2 instead.");

@end

NS_ASSUME_NONNULL_END
