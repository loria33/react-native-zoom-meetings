
#import "RNZoomBridge.h"

@implementation RNZoomBridge
{
  BOOL isInitialized;
  RCTPromiseResolveBlock initializePromiseResolve;
  RCTPromiseRejectBlock initializePromiseReject;
  RCTPromiseResolveBlock meetingPromiseResolve;
  RCTPromiseRejectBlock meetingPromiseReject;
  RCTPromiseResolveBlock loginPromiseResolve;
  RCTPromiseRejectBlock loginPromiseReject;
}

- (instancetype)init {
  if (self = [super init]) {
    isInitialized = NO;
    initializePromiseResolve = nil;
    initializePromiseReject = nil;
    meetingPromiseResolve = nil;
    meetingPromiseReject = nil;
    loginPromiseReject = nil;
    loginPromiseResolve = nil;
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
  initialize: (NSString *)appKey
  withAppSecret: (NSString *)appSecret
  withWebDomain: (NSString *)webDomain
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
    initializePromiseResolve = resolve;
    initializePromiseReject = reject;
    
  if (isInitialized) {
      NSObject *output=[NSNumber numberWithBool:[[[MobileRTC sharedRTC] getAuthService] isLoggedIn]];
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
      output , @"isloggedIN",nil];
      initializePromiseResolve(dict);
      //resolve(@"Already initialize Zoom SDK successfully.");       
    return;
  }

  isInitialized = true;

  @try {
   
    [[MobileRTC sharedRTC] setMobileRTCDomain:webDomain];

    MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
    if (authService)
    {
      authService.delegate = self;

      authService.clientKey = appKey;
      authService.clientSecret = appSecret;

      [authService sdkAuth];
    } else {
      NSLog(@"onZoomSDKInitializeResult, no authService");
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing initialize", ex);
  }
}

RCT_EXPORT_METHOD(
  startMeeting: (NSString *)displayName
  withMeetingNo: (NSString *)meetingNo
  withUserId: (NSString *)userId
  withUserType: (NSInteger)userType
  withZoomAccessToken: (NSString *)zoomAccessToken
  withZoomToken: (NSString *)zoomToken
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {
    meetingPromiseResolve = resolve;
    meetingPromiseReject = reject;

    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
      ms.delegate = self;

      MobileRTCMeetingStartParam4WithoutLoginUser * params = [[MobileRTCMeetingStartParam4WithoutLoginUser alloc]init];
      params.userName = displayName;
      params.meetingNumber = meetingNo;
      params.userID = userId;
      params.userType = (MobileRTCUserType)userType;
      params.zak = zoomAccessToken;
      params.userToken = zoomToken;

      MobileRTCMeetError startMeetingResult = [ms startMeetingWithStartParam:params];
      NSLog(@"startMeeting, startMeetingResult=%d", startMeetingResult);
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing startMeeting", ex);
  }
}

RCT_EXPORT_METHOD(
  joinMeeting: (NSString *)displayName
  withMeetingNo: (NSString *)meetingNo
  withMeetingPwd:(NSString *)pwd
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {
    meetingPromiseResolve = resolve;
    meetingPromiseReject = reject;

    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
      ms.delegate = self;

      NSDictionary *paramDict = @{
        kMeetingParam_Username: displayName,
        kMeetingParam_MeetingNumber: meetingNo,
        kMeetingParam_MeetingPassword:pwd
        
      };

      MobileRTCMeetError joinMeetingResult = [ms joinMeetingWithDictionary:paramDict];
      NSLog(@"joinMeeting, joinMeetingResult=%d", joinMeetingResult);
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing joinMeeting", ex);
  }
}

- (void)onMobileRTCAuthReturn:(MobileRTCAuthError)returnValue {
  NSLog(@"nZoomSDKInitializeResult, errorCode=%d", returnValue);
  if(returnValue != MobileRTCAuthError_Success) {
    initializePromiseReject(
      @"ERR_ZOOM_INITIALIZATION",
      [NSString stringWithFormat:@"Error: %d", returnValue],
      [NSError errorWithDomain:@"us.zoom.sdk" code:returnValue userInfo:nil]
    );
  } else {
      NSObject *output=[NSNumber numberWithBool:[[[MobileRTC sharedRTC] getAuthService] isLoggedIn]];
     
      NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
                 output , @"isloggedIN",nil];
             
      initializePromiseResolve(dict);
  }
}

- (void)onMeetingReturn:(MobileRTCMeetError)errorCode internalError:(NSInteger)internalErrorCode {
  NSLog(@"onMeetingReturn, error=%d, internalErrorCode=%zd", errorCode, internalErrorCode);

  if (!meetingPromiseResolve) {
    return;
  }

  if (errorCode != MobileRTCMeetError_Success) {
    meetingPromiseReject(
      @"ERR_ZOOM_MEETING_1_1",
      [NSString stringWithFormat:@"Error: %d, internalErrorCode=%zd", errorCode, internalErrorCode],
      [NSError errorWithDomain:@"us.zoom.sdk" code:errorCode userInfo:nil]
    );
  } else {
    meetingPromiseResolve(@"Connected to zoom meeting");
  }

  meetingPromiseResolve = nil;
  meetingPromiseReject = nil;
}

- (void)onMeetingStateChange:(MobileRTCMeetingState)state {
  NSLog(@"onMeetingStatusChanged, meetingState=%d", state);

  if (state == MobileRTCMeetingState_InMeeting || state == MobileRTCMeetingState_Idle) {
    if (!meetingPromiseResolve) {
       
      return;
    }
     
    meetingPromiseResolve(@"Connected to zoom meeting");

    meetingPromiseResolve = nil;
    meetingPromiseReject = nil;
  }
}

- (void)onMeetingError:(MobileRTCMeetError)errorCode message:(NSString *)message {
  NSLog(@"onMeetingError, errorCode=%d, message=%@", errorCode, message);

    if(errorCode == MobileRTCMeetError_Success && [message isEqualToString:@"success"]) {
         NSString *meetingNo = [[MobileRTCInviteHelper sharedInstance] ongoingMeetingNumber];
        // NSString *meetingPassword = [[MobileRTCInviteHelper sharedInstance] meetingPassword];
         NSString *rawMeetingPassword = [[MobileRTCInviteHelper sharedInstance] rawMeetingPassword];
         //NSString *inviteCopyURL = [[MobileRTCInviteHelper sharedInstance] inviteCopyURL];
        
           NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:
            rawMeetingPassword, @"pwd", meetingNo, @"id",nil];
         meetingPromiseResolve(dict);
    }
    else {
        meetingPromiseReject(
        @"ERR_ZOOM_MEETING_1",
        [NSString stringWithFormat:@"Error: %d, internalErrorCode=%@", errorCode, message],
        [NSError errorWithDomain:@"us.zoom.sdk" code:errorCode userInfo:nil]
        );
    }
  meetingPromiseResolve = nil;
  meetingPromiseReject = nil;
}

///Login//
RCT_EXPORT_METHOD(
  loginWithEmail: (NSString *)email
  withpassword: (NSString *)password
  withremeberMe:(BOOL)rememberMe
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
    
    loginPromiseResolve = resolve;
    loginPromiseReject = reject;
    [[[MobileRTC sharedRTC] getAuthService] loginWithEmail:email password:password remeberMe:YES];
}

- (void)onMobileRTCLoginReturn:(NSInteger)returnValue
{
    
    if(returnValue == 0){
        if (!loginPromiseResolve) {
             return;
        }
        loginPromiseResolve(@"Login succesful");
    }
    else {
        if(returnValue == 1002) {
            loginPromiseReject(
              @"ERR_ZOOM_MEETING_2",
              [NSString stringWithFormat:@"Error:Login Failed check your password"],
              [NSError errorWithDomain:@"us.zoom.sdk" code:1002 userInfo:nil]
            );
        }
        else {
            loginPromiseReject(
              @"ERR_ZOOM_MEETING_4",
              [NSString stringWithFormat:@"Error:Login Error"],
              [NSError errorWithDomain:@"us.zoom.sdk" code:99 userInfo:nil]
            );
        }
    }
     
    loginPromiseResolve = nil;
    loginPromiseReject = nil;
    return;
}


RCT_EXPORT_METHOD(
  startLoginMeeting: (NSString *)displayName
  withResolve: (RCTPromiseResolveBlock)resolve
  withReject: (RCTPromiseRejectBlock)reject
)
{
  @try {
    meetingPromiseResolve = resolve;
    meetingPromiseReject = reject;

    MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
    if (ms) {
      ms.delegate = self;
        
        NSString *kSDKMeetingNumber = @"";
        //Sample for Start Param interface
        MobileRTCMeetingStartParam * param = nil;
        MobileRTCMeetingStartParam4LoginlUser * user = [[MobileRTCMeetingStartParam4LoginlUser alloc]init];
        param = user;
        param.meetingNumber = kSDKMeetingNumber; // if kSDKMeetNumber is empty, it‘s a instant meeting.
        param.isAppShare = false;
        MobileRTCMeetError ret = [ms startMeetingWithStartParam:param];
        NSLog(@"onMeetNow ret:%d", ret);
     
        return;
        
    }
  } @catch (NSError *ex) {
      reject(@"ERR_UNEXPECTED_EXCEPTION", @"Executing startMeeting", ex);
  }
}


@end
