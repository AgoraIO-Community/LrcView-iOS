//
//  RtcTokenTool.m
//  RTMTokenBuilder
//
//  Created by ZYP on 2023/10/27.
//

#import "RtcTokenTool.h"
#import "RtcTokenBuilder2.h"

@implementation RtcTokenTool
+ (NSString *)rtcToken2:(NSString *)appId
      appCertificate:(NSString *)appCertificate
                 uid:(int)uid
            channelName:(NSString *)channelName{
    
    std::string cAppId = [appId UTF8String];
    std::string cAppCertificate = [appCertificate UTF8String];
    uint32_t cUid = uint32_t(uid);
    std::string cChannel = [channelName UTF8String];
    uint32_t expe = 60 * 60 * 24;
    std::string lastCstr = agora::tools::RtcTokenBuilder2::BuildTokenWithUid(cAppId, cAppCertificate, cChannel, cUid, expe);

    NSString *token = [NSString stringWithCString:lastCstr.c_str() encoding:[NSString defaultCStringEncoding]];
    return token;
}
@end
