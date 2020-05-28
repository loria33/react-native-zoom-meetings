#!/bin/sh

rm -f -r ./node_modules/react-native-zoom-meetings/ios/libs && \
mkdir -p ./node_modules/react-native-zoom-meetings/ios/libs && \
mkdir -p ./node_modules/react-native-zoom-meetings/ios/libs/MobileRTC && \

cd ./node_modules/react-native-meetings/ios/libs && \
curl -L https://github.com/zoom/zoom-sdk-ios/archive/master.zip > file.zip && \
unzip file.zip && \
cd zoom-sdk-ios-master/lib && \
mv * ../../ && \
cd ../../ && \
rm file.zip && \
rm -r zoom-sdk-ios-master
