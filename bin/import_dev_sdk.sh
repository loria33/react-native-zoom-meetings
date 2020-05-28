#!/bin/sh

rm -f -r ./node_modules/react-native-zoom-meetings/ios/libs && \
mkdir -p ./node_modules/react-native-zoom-meetings/ios/libs && \
cd ./node_modules/react-native-zoom-meetings/ios/libs && \
curl -L https://github.com/zoom/zoom-sdk-ios/releases/download/v4.6.15084.0206/ios-mobilertc-all-4.6.15084.0206-n.zip > file.zip && \
unzip file.zip && \
cd lib && \
mv * ../ && \
cd ../ && \
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTC.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+AppShare.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+Audio.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+Chat.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+Customize.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+inMeeting.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+User.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+Video.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+VirtualBackground.h
sed -i.bak 's/#import <MobileRTC\//#import </g' ./MobileRTC.framework/Headers/MobileRTCMeetingService+Webinar.h
rm file.zip && \
rm -r lib && \
rm -r MobileRTCSample
