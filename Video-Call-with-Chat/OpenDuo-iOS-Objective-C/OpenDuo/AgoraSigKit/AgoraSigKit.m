#import "AgoraSigKit.h"

@interface AgoraAPI ()<AgoraRtmDelegate>
@property (strong, nonatomic) AgoraRtmKit *rtmKit;
@end

@implementation AgoraAPI

NSString *SIGNAL_PREFIX = @"SIG_";
NSString *SIG_QUERY_USER_STATUS = @"SIG_QUERY_USER_STATUS";
NSString *SIG_CHANNEL_INVITE_USER = @"SIG_CHANNEL_INVITE_USER";
NSString *SIG_CHANNEL_INVITE_ACCEPT = @"SIG_CHANNEL_INVITE_ACCEPT";
NSString *SIG_CHANNEL_INVITE_REFUSE = @"SIG_CHANNEL_INVITE_REFUSE";
NSString *SIG_CHANNEL_INVITE_END = @"SIG_CHANNEL_INVITE_END";
NSString *SIG_CHANNEL_INVITE_USER2 = @"SIG_CHANNEL_INVITE_USER2";

+ (AgoraAPI*)getInstanceWithoutMedia:(NSString *)vendorKey {
    static AgoraAPI *agoraAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        agoraAPI = [[AgoraAPI alloc] init];
        agoraAPI.rtmKit = [[AgoraRtmKit alloc] initWithAppId:vendorKey delegate:agoraAPI];
    });
    
    return agoraAPI;
}

- (void)login:(NSString *)vendorID account:(NSString *)account token:(NSString *)token uid:(uint32_t)uid deviceID:(NSString *)deviceID {
    __weak typeof(self) weakSelf = self;
    [self.rtmKit loginByToken:token user:account completion:^(AgoraRtmLoginErrorCode errorCode) {
        if (errorCode == AgoraRtmLoginErrorOk) {
            weakSelf.onLoginSuccess(account);
        } else {
            weakSelf.onLoginFailed(errorCode);
        }
    }];
}

- (void)logout {
    __weak typeof(self) weakSelf = self;
    [self.rtmKit logoutWithCompletion:^(AgoraRtmLogoutErrorCode errorCode) {
        weakSelf.onLogout(errorCode);
    }];
}

- (void)queryUserStatus:(NSString *)account {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_QUERY_USER_STATUS];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessageToPeer:account message:message completion:^(AgoraRtmSendPeerMessageState state) {
        NSString* status = (state == AgoraRtmSendPeerMessageStateReceivedByPeer ? @"1" : @"0");
        weakSelf.onQueryUserStatusResult(account, status);
    }];
}

- (void)channelInviteUser:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_CHANNEL_INVITE_USER];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessageToPeer:account message:message completion:^(AgoraRtmSendPeerMessageState state) {
        if (state == AgoraRtmSendPeerMessageStateReceivedByPeer) {
            weakSelf.onInviteReceivedByPeer(channelID, account, uid);
        } else {
            weakSelf.onInviteFailed(channelID, account, 0, state, nil);
        }
    }];
}

- (void)channelInviteUser2:(NSString *)channelID account:(NSString *)account extra:(NSString *)extra {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_CHANNEL_INVITE_USER2];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessageToPeer:account message:message completion:^(AgoraRtmSendPeerMessageState state) {
        if (state == AgoraRtmSendPeerMessageStateReceivedByPeer) {
            weakSelf.onInviteReceivedByPeer(channelID, account, 0);
        } else {
            weakSelf.onInviteFailed(channelID, account, 0, state, nil);
        }
    }];
}

- (void)channelInviteAccept:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_CHANNEL_INVITE_ACCEPT];
    [self.rtmKit sendMessageToPeer:account message:message completion:nil];
}

- (void)channelInviteRefuse:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_CHANNEL_INVITE_REFUSE];
    [self.rtmKit sendMessageToPeer:account message:message completion:nil];
}

- (void)channelInviteEnd:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_CHANNEL_INVITE_END];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessageToPeer:account message:message completion:^(AgoraRtmSendPeerMessageState state) {
        weakSelf.onInviteEndByMyself(channelID, account, uid);
    }];
}

- (void)rtmKit:(AgoraRtmKit *)kit connectionStateChanged:(AgoraRtmConnectionState)state {
    switch (state) {
        case AgoraRtmConnectionStateConnected:
            self.onReconnected(0);
            break;
        case AgoraRtmConnectionStateDisConnected:
            self.onReconnecting(-1);
        default:
            break;
    }
}

- (void)rtmKit:(AgoraRtmKit *)kit messageReceived:(AgoraRtmMessage *)message fromPeer:(NSString *)peerId {
    NSString *text = message.text;
    if (!text.length) {
        return;
    }
    
    if ([text hasPrefix:SIGNAL_PREFIX]) {
        [self handleSignalString:text fromPeer:peerId];
    }
}

- (void)handleSignalString:(NSString *)string fromPeer:(NSString *)peerId {
    if ([string isEqualToString:SIG_CHANNEL_INVITE_USER] || [string isEqualToString:SIG_CHANNEL_INVITE_USER2]) {
        self.onInviteReceived(nil, peerId, 0, nil);
    } else if ([string isEqualToString:SIG_CHANNEL_INVITE_ACCEPT]) {
        self.onInviteAcceptedByPeer(nil, peerId, 0, nil);
    } else if ([string isEqualToString:SIG_CHANNEL_INVITE_REFUSE]) {
        self.onInviteRefusedByPeer(nil, peerId, 0, nil);
    } else if ([string isEqualToString:SIG_CHANNEL_INVITE_END]) {
        self.onInviteEndByPeer(nil, peerId, 0, nil);
    }
}
@end
