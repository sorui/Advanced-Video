
#ifndef io_agora_sdk2_h
#define io_agora_sdk2_h

#import <Foundation/Foundation.h>
#import <AgoraRtcEngineKit/AgoraRtmKit.h>

@interface AgoraAPI : NSObject

@property (copy) void(^onLoginSuccess)(NSString *account);
@property (copy) void(^onLoginFailed)(AgoraRtmLoginErrorCode ecode);
@property (copy) void(^onLogout)(AgoraRtmLogoutErrorCode ecode);

@property (copy) void(^onReconnecting)(uint32_t nretry);
@property (copy) void(^onReconnected)(int fd);

@property (copy) void(^onInviteReceived)(NSString *channelID, NSString *account,uint32_t uid,NSString *extra);
@property (copy) void(^onInviteReceivedByPeer)(NSString *channelID,NSString *account,uint32_t uid);
@property (copy) void(^onInviteAcceptedByPeer)(NSString *channelID,NSString *account,uint32_t uid,NSString *extra);
@property (copy) void(^onInviteRefusedByPeer)(NSString *channelID,NSString *account,uint32_t uid,NSString *extra);
@property (copy) void(^onInviteFailed)(NSString *channelID,NSString *account,uint32_t uid, AgoraRtmSendPeerMessageState ecode,NSString *extra);
@property (copy) void(^onInviteEndByPeer)(NSString *channelID,NSString *account,uint32_t uid,NSString *extra);
@property (copy) void(^onInviteEndByMyself)(NSString *channelID,NSString *account,uint32_t uid);

@property (copy) void(^onQueryUserStatusResult)(NSString* name,NSString* status);
@property (copy) void(^onError)(NSString *name, NSInteger ecode, NSString *desc);

+ (AgoraAPI*)getInstanceWithoutMedia:(NSString *)vendorKey;

/**
 Log into Agora's Signaling System. Users must always log in before performing any operation.

 @param appId The App ID provided by Agora
 @param account User ID defined by the client. It can be up to 64 visible characters (space and "null" is not allowed).
 @param token token
 @param uid N/A: Set it as 0
 @param deviceID Set it as nil
 */
- (void)login:(NSString *)appId account:(NSString *)account token:(NSString *)token uid:(uint32_t)uid deviceID:(NSString *)deviceID;

/**
 Log out of the Agora's Signaling System.
 */
- (void)logout;

- (void)queryUserStatus:(NSString *)account;

- (void)channelInviteUser:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid;
- (void)channelInviteUser2:(NSString *)channelID account:(NSString *)account extra:(NSString *)extra;

- (void)channelInviteAccept:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra;
- (void)channelInviteRefuse:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra;
- (void)channelInviteEnd:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid;

@end

#endif
