package com.appgoalz.reactnative;

import android.util.Log;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;


import org.json.JSONObject;

import us.zoom.sdk.ZoomSDK;
import us.zoom.sdk.ZoomError;
import us.zoom.sdk.ZoomSDKInitializeListener;
import us.zoom.sdk.ZoomSDKAuthenticationListener;

import us.zoom.sdk.MeetingStatus;
import us.zoom.sdk.MeetingError;
import us.zoom.sdk.MeetingService;
import us.zoom.sdk.MeetingServiceListener;
import us.zoom.sdk.InstantMeetingOptions;
import us.zoom.sdk.InMeetingService;

import us.zoom.sdk.StartMeetingOptions;
import us.zoom.sdk.StartMeetingParamsWithoutLogin;

import us.zoom.sdk.JoinMeetingOptions;
import us.zoom.sdk.JoinMeetingParams;

public class RNZoomBridgeModule extends ReactContextBaseJavaModule implements ZoomSDKAuthenticationListener,ZoomSDKInitializeListener, MeetingServiceListener, LifecycleEventListener {

  private final static String TAG = "RNZoomBridge";
  private final ReactApplicationContext reactContext;

  private Boolean isInitialized = false;
  private Promise initializePromise;
  private Promise loginPromise;
  private Promise meetingPromise;
  private Promise instantmeetingPromise;

  public RNZoomBridgeModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addLifecycleEventListener(this);
  }

  @Override
  public String getName() {
    return "RNZoomBridge";
  }

  @ReactMethod
  public void initialize(final String appKey, final String appSecret, final String webDomain, final Promise promise) {
    if (isInitialized) {

      WritableMap map = Arguments.createMap();
      map.putBoolean("isloggedIN", (Boolean)ZoomSDK.getInstance().isLoggedIn());
      promise.resolve(map);

      return;
    }

    isInitialized = true;

    try {
      initializePromise = promise;

      reactContext.getCurrentActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            ZoomSDK zoomSDK = ZoomSDK.getInstance();
            zoomSDK.initialize(reactContext.getCurrentActivity(), appKey, appSecret, webDomain, RNZoomBridgeModule.this);
          }
      });
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @ReactMethod
  public void startMeeting(
    final String displayName,
    final String meetingNo,
    final String userId,
    final int userType,
    final String zoomAccessToken,
    final String zoomToken,
    Promise promise
  ) {
    try {
      meetingPromise = promise;

      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_START", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();
      if(meetingService.getMeetingStatus() != MeetingStatus.MEETING_STATUS_IDLE) {
        long lMeetingNo = 0;
        try {
          lMeetingNo = Long.parseLong(meetingNo);
        } catch (NumberFormatException e) {
          promise.reject("ERR_ZOOM_START", "Invalid meeting number: " + meetingNo);
          return;
        }

        if(meetingService.getCurrentRtcMeetingNumber() == lMeetingNo) {
          meetingService.returnToMeeting(reactContext.getCurrentActivity());
          promise.resolve("Already joined zoom meeting");
          return;
        }
      }

      StartMeetingOptions opts = new StartMeetingOptions();
      StartMeetingParamsWithoutLogin params = new StartMeetingParamsWithoutLogin();
      params.displayName = displayName;
      params.meetingNo = meetingNo;
      params.userId = userId;
      params.userType = userType;
      params.zoomAccessToken = zoomAccessToken;
      params.zoomToken = zoomToken;

      int startMeetingResult = meetingService.startMeetingWithParams(reactContext.getCurrentActivity(), params, opts);
      Log.i(TAG, "startMeeting, startMeetingResult=" + startMeetingResult);

      if (startMeetingResult != MeetingError.MEETING_ERROR_SUCCESS) {
        promise.reject("ERR_ZOOM_START", "startMeeting, errorCode=" + startMeetingResult);
      }
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }


  @ReactMethod
  public void startLoginMeeting(
    final String displayName,
            Promise promise )
  {
    try {
      instantmeetingPromise = promise;

      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();
      InstantMeetingOptions opts = new InstantMeetingOptions();
      int joinMeetingResult =  meetingService.startInstantMeeting(reactContext.getCurrentActivity(), opts);

    }
    catch(Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }
  @ReactMethod
  public void joinMeeting(
    final String displayName,
    final String meetingNo,
    final String pwd,
    Promise promise
  ) {
    try {
      meetingPromise = promise;

      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();

      JoinMeetingOptions opts = new JoinMeetingOptions();
      JoinMeetingParams params = new JoinMeetingParams();
      params.displayName = displayName;
      params.meetingNo = meetingNo;
      params.password = pwd;

      int joinMeetingResult = meetingService.joinMeetingWithParams(reactContext.getCurrentActivity(), params, opts);
      Log.i(TAG, "joinMeeting, joinMeetingResult=" + joinMeetingResult);

      if (joinMeetingResult != MeetingError.MEETING_ERROR_SUCCESS) {
        promise.reject("ERR_ZOOM_JOIN", "joinMeeting, errorCode=" + joinMeetingResult);
      }
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }

  @ReactMethod
  public void joinMeetingWithPassword(
    final String displayName,
    final String meetingNo,
    final String password,
    Promise promise
  ) {
    try {
      meetingPromise = promise;

      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_JOIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      final MeetingService meetingService = zoomSDK.getMeetingService();

      JoinMeetingOptions opts = new JoinMeetingOptions();
      JoinMeetingParams params = new JoinMeetingParams();
      params.displayName = displayName;
      params.meetingNo = meetingNo;
      params.password = password;

      int joinMeetingResult = meetingService.joinMeetingWithParams(reactContext.getCurrentActivity(), params, opts);
      Log.i(TAG, "joinMeeting, joinMeetingResult=" + joinMeetingResult);

      if (joinMeetingResult != MeetingError.MEETING_ERROR_SUCCESS) {
        promise.reject("ERR_ZOOM_JOIN", "joinMeeting, errorCode=" + joinMeetingResult);
      }
    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }


  @ReactMethod
  public void loginWithEmail(
          final String email,
          final String pwd,
          final Boolean rememberMe,
          Promise promise
  ) {
    try {
      loginPromise = promise;

      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      zoomSDK.addAuthenticationListener(this);
      if(!zoomSDK.isInitialized()) {
        promise.reject("ERR_ZOOM_LOGIN", "ZoomSDK has not been initialized successfully");
        return;
      }

      if (email.length() == 0 || pwd.length() == 0) {
        promise.reject("ERR_ZOOM_LOGIN","Username and password cannot be empty.");
        return;
      }

      int response = zoomSDK.loginWithZoom(email,pwd);

     return;

    } catch (Exception ex) {
      promise.reject("ERR_UNEXPECTED_EXCEPTION", ex);
    }
  }


  @Override
  public void onZoomSDKLoginResult(long result) {
    if(result == 0) {
      loginPromise.resolve("Login succesful");
    }
    else
    {
      if(result == 1002) {
        loginPromise.reject("ERR_LOGIN_ZOOM_USER","Login Failed check your password");
      }
      else {
        loginPromise.reject("ERR_LOGIN_ZOOM","Login Failed");
      }

    }
  }

  @Override
  public void onZoomSDKLogoutResult(long l) {
    int x = 1;
    x=x+2;
  }

  @Override
  public void onZoomIdentityExpired() {

  }

  @Override
  public void onZoomSDKInitializeResult(int errorCode, int internalErrorCode) {
    Log.i(TAG, "onZoomSDKInitializeResult, errorCode=" + errorCode + ", internalErrorCode=" + internalErrorCode);
    if(errorCode != ZoomError.ZOOM_ERROR_SUCCESS) {
      initializePromise.reject(
              "ERR_ZOOM_INITIALIZATION",
              "Error: " + errorCode + ", internalErrorCode=" + internalErrorCode
      );
    } else {
      registerListener();
      WritableMap map = Arguments.createMap();
      map.putBoolean("isloggedIN", (Boolean)ZoomSDK.getInstance().isLoggedIn());
      initializePromise.resolve(map);
     // initializePromise.resolve("Initialize Zoom SDK successfully.");
    }
  }

  @Override
  public void onMeetingStatusChanged(MeetingStatus meetingStatus, int errorCode, int internalErrorCode) {
    Log.i(TAG, "onMeetingStatusChanged, meetingStatus=" + meetingStatus + ", errorCode=" + errorCode + ", internalErrorCode=" + internalErrorCode);

    if (meetingPromise == null && instantmeetingPromise == null) {
      return;
    }

    if(meetingStatus == MeetingStatus.MEETING_STATUS_FAILED) {
      meetingPromise.reject(
              "ERR_ZOOM_MEETING",
              "Error: " + errorCode + ", internalErrorCode=" + internalErrorCode
      );
      meetingPromise = null;
      instantmeetingPromise = null;



    }else if(meetingStatus == MeetingStatus.MEETING_STATUS_DISCONNECTING) {
      // Do something when meeting ends
    }
    else if (meetingStatus == MeetingStatus.MEETING_STATUS_INMEETING) {
      ZoomSDK zoomSDK = ZoomSDK.getInstance();
      final InMeetingService meetingService = zoomSDK.getInMeetingService();

      WritableMap map = Arguments.createMap();
      map.putDouble("id", (double) meetingService.getCurrentMeetingNumber());
      map.putString("pwd", meetingService.getMeetingPassword());

      if (instantmeetingPromise != null) {
          instantmeetingPromise.resolve(map);
      }
      if (meetingPromise != null) {
          meetingPromise.resolve(map);
      }


      meetingPromise = null;
      instantmeetingPromise = null;
    }
  }

  @Override
  public void onZoomAuthIdentityExpired() {
    Log.d(TAG,"onZoomAuthIdentityExpired:");
  }

  private void registerListener() {
    Log.i(TAG, "registerListener");
    ZoomSDK zoomSDK = ZoomSDK.getInstance();
    MeetingService meetingService = zoomSDK.getMeetingService();
    if(meetingService != null) {
      meetingService.addListener(this);
    }
  }

  private void unregisterListener() {
    Log.i(TAG, "unregisterListener");
    ZoomSDK zoomSDK = ZoomSDK.getInstance();
    if(zoomSDK.isInitialized()) {
      MeetingService meetingService = zoomSDK.getMeetingService();
      meetingService.removeListener(this);
    }
  }

  @Override
  public void onCatalystInstanceDestroy() {
    unregisterListener();
  }

  // React LifeCycle
  @Override
  public void onHostDestroy() {
    unregisterListener();
  }
  @Override
  public void onHostPause() {}
  @Override
  public void onHostResume() {}


}
