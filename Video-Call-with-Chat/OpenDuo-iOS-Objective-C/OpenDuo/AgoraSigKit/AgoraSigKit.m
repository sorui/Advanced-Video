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
            if (weakSelf.onLoginSuccess) {
                weakSelf.onLoginSuccess(account);
            }
        } else {
            if (weakSelf.onLoginFailed) {
                weakSelf.onLoginFailed(errorCode);
            }
        }
    }];
}

- (void)logout {
    __weak typeof(self) weakSelf = self;
    [self.rtmKit logoutWithCompletion:^(AgoraRtmLogoutErrorCode errorCode) {
        if (weakSelf.onLogout) {
            weakSelf.onLogout(errorCode);
        }
    }];
}

- (void)queryUserStatus:(NSString *)account {
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:SIG_QUERY_USER_STATUS];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessage:message toPeer:account completion:^(AgoraRtmSendPeerMessageState state) {
        NSString* status = (state == AgoraRtmSendPeerMessageStateReceivedByPeer ? @"1" : @"0");
        if (weakSelf.onQueryUserStatusResult) {
            weakSelf.onQueryUserStatusResult(account, status);
        }
    }];
}

- (void)channelInviteUser:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid {
    NSString *text = [self appendChannel:channelID toString:SIG_CHANNEL_INVITE_USER];
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:text];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessage:message toPeer:account completion:^(AgoraRtmSendPeerMessageState state) {
        if (state == AgoraRtmSendPeerMessageStateReceivedByPeer) {
            if (weakSelf.onInviteReceivedByPeer) {
                weakSelf.onInviteReceivedByPeer(channelID, account, uid);
            }
        } else {
            if (weakSelf.onInviteFailed) {
                weakSelf.onInviteFailed(channelID, account, 0, state, nil);
            }
        }
    }];
}

- (void)channelInviteUser2:(NSString *)channelID account:(NSString *)account extra:(NSString *)extra {
    NSString *text = [self appendChannel:channelID toString:SIG_CHANNEL_INVITE_USER2];
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:text];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessage:message toPeer:account completion:^(AgoraRtmSendPeerMessageState state) {
        if (state == AgoraRtmSendPeerMessageStateReceivedByPeer) {
            if (weakSelf.onInviteReceivedByPeer) {
                weakSelf.onInviteReceivedByPeer(channelID, account, 0);
            }
        } else {
            if (weakSelf.onInviteFailed) {
                weakSelf.onInviteFailed(channelID, account, 0, state, nil);
            }
        }
    }];
}

- (void)channelInviteAccept:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra {
    NSString *text = [self appendChannel:channelID toString:SIG_CHANNEL_INVITE_ACCEPT];
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:text];
    [self.rtmKit sendMessage:message toPeer:account completion:nil];
}

- (void)channelInviteRefuse:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid extra:(NSString *)extra {
    NSString *text = [self appendChannel:channelID toString:SIG_CHANNEL_INVITE_REFUSE];
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:text];
    [self.rtmKit sendMessage:message toPeer:account completion:nil];
}

- (void)channelInviteEnd:(NSString *)channelID account:(NSString *)account uid:(uint32_t)uid {
    NSString *text = [self appendChannel:channelID toString:SIG_CHANNEL_INVITE_END];
    AgoraRtmMessage *message = [[AgoraRtmMessage alloc] initWithText:text];
    __weak typeof(self) weakSelf = self;
    [self.rtmKit sendMessage:message toPeer:account completion:^(AgoraRtmSendPeerMessageState state) {
        if (weakSelf.onInviteEndByMyself) {
            weakSelf.onInviteEndByMyself(channelID, account, uid);
        }
    }];
}

- (void)rtmKit:(AgoraRtmKit *)kit connectionStateChanged:(AgoraRtmConnectionState)state {
    switch (state) {
        case AgoraRtmConnectionStateConnected:
            if (self.onReconnected) {
                self.onReconnected(0);
            }
            break;
        case AgoraRtmConnectionStateDisConnected:
            if (self.onReconnecting) {
                self.onReconnecting(-1);
            }
        default:
            break;
    }
}

- (void)rtmKit:(AgoraRtmKit *)kit messageReceived:(AgoraRtmMessage *)message fromPeer:(NSString *)peerId {
    NSString *text = message.text;
    NSLog(@"==handleSignalString: %@", text);
    if (!text.length) {
        return;
    }
    
    if ([text hasPrefix:SIGNAL_PREFIX]) {
        [self handleSignalString:text fromPeer:peerId];
    }
}

- (void)handleSignalString:(NSString *)string fromPeer:(NSString *)peerId {
    if ([string hasPrefix:SIG_CHANNEL_INVITE_USER]) {
        if (self.onInviteReceived) {
            NSString *channel = [self channelFromString:string prefix:SIG_CHANNEL_INVITE_USER];
            self.onInviteReceived(channel, peerId, 0, nil);
        }
    } else if ([string hasPrefix:SIG_CHANNEL_INVITE_USER2] ) {
        if (self.onInviteReceived) {
            NSString *channel = [self channelFromString:string prefix:SIG_CHANNEL_INVITE_USER2];
            self.onInviteReceived(channel, peerId, 0, nil);
        }
    } else if ([string hasPrefix:SIG_CHANNEL_INVITE_ACCEPT]) {
        if (self.onInviteAcceptedByPeer) {
            NSString *channel = [self channelFromString:string prefix:SIG_CHANNEL_INVITE_ACCEPT];
            self.onInviteAcceptedByPeer(channel, peerId, 0, nil);
        }
    } else if ([string hasPrefix:SIG_CHANNEL_INVITE_REFUSE]) {
        if (self.onInviteRefusedByPeer) {
            NSString *channel = [self channelFromString:string prefix:SIG_CHANNEL_INVITE_REFUSE];
            self.onInviteRefusedByPeer(channel, peerId, 0, nil);
        }
    } else if ([string hasPrefix:SIG_CHANNEL_INVITE_END]) {
        if (self.onInviteEndByPeer) {
            NSString *channel = [self channelFromString:string prefix:SIG_CHANNEL_INVITE_END];
            self.onInviteEndByPeer(channel, peerId, 0, nil);
        }
    }
}

- (NSString *)appendChannel:(NSString *)channel toString:(NSString *)string {
    NSString *text = [NSString stringWithFormat:@"%@:%@", string, channel];
    NSLog(@"===text: %@", text);
    return text;
}

- (NSString *)channelFromString:(NSString *)string prefix:(NSString *)prefix {
    NSString *prefixToRemove = [NSString stringWithFormat:@"%@:", prefix];
    if ([string hasPrefix:prefixToRemove]) {
        return [string substringFromIndex:[prefixToRemove length]];
    } else {
        return string;
    }
}
@end
