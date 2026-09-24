//
//  RtcTokenTool.m
//  AgoraEducation
//
//  Created by Jerry on 2019/10/11.
//  Copyright © 2019 Jerry. All rights reserved.
//

#import "RtmTokenTool.h"
#import "RtmTokenBuilder.h"
#import "RtmTokenBuilder2.h"

@implementation RtmTokenTool

+ (NSString *)token:(NSString *)appId appCertificate:(NSString *)appCertificate uid:(NSString *)uid  {
    
    std::string cAppId = [appId UTF8String];
    std::string cAppCertificate = [appCertificate UTF8String];
    std::string cUid = [uid UTF8String];
    uint32_t expe = 60 * 60 * 24;
    std::string lastCstr =  agora::tools::RtmTokenBuilder::buildToken(cAppId, cAppCertificate, cUid, agora::tools::RtmUserRole::Rtm_User, expe);

    NSString *token = [NSString stringWithCString:lastCstr.c_str() encoding:[NSString defaultCStringEncoding]];
    return token;
}


+ (NSString *)token2:(NSString *)appId
      appCertificate:(NSString *)appCertificate
                 uid:(NSString *)uid {
    
    std::string cAppId = [appId UTF8String];
    std::string cAppCertificate = [appCertificate UTF8String];
    std::string cUid = [uid UTF8String];
    uint32_t expe = 60 * 60 * 24;
    std::string lastCstr = agora::tools::RtmTokenBuilder2::BuildToken(cAppId, cAppCertificate, cUid, expe);

    NSString *token = [NSString stringWithCString:lastCstr.c_str() encoding:[NSString defaultCStringEncoding]];
    return token;
}

@end
