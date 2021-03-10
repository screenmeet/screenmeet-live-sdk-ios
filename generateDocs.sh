#!/bin/bash

#
# Jazzy home page https://github.com/realm/jazzy
#
# Install Jazzy as gem
# 
# [sudo] gem install jazzy
#

jazzy --clean --sdk iphoneos -x -workspace,Example/ScreenMeet.xcworkspace,-scheme,ScreenMeetSDK,-sdk,iphoneos,-arch,arm64,-CODE_SIGNING_ALLOWED=NO --module ScreenMeetSDK --min-acl public

