#PopcornTime TV
[![Build Status](https://travis-ci.org/PopcornTimeTV/PopcornTimeTV.svg?branch=master)](https://travis-ci.org/PopcornTimeTV/PopcornTimeTV)
[![Slack Status](https://popcorntimetv.herokuapp.com/badge.svg)](https://popcorntimetv.herokuapp.com)

**NOTE: You must build the project with Xcode 7. Swift 3 and Xcode 8 support will be available when tvOS 10 launched in the fall.**

An Apple TV 4 application to torrent movies and tv shows for streaming.
A simple and easy to use application based on TVML to bring the native desktop
PopcornTime experience to Apple TV.

##Version
Release notes for every version can be [found here](https://github.com/PopcornTimeTV/PopcornTimeTV/releases)

##Setup

PopcornTime requires cocoapods. 
To install it simply open Terminal and enter the following command

`gem install cocoapods`

Setting up PopcornTime is quite easy.
*Open Terminal to run the following commands*

```
cd ~/Desktop
git clone https://github.com/PopcornTimeTV/PopcornTimeTV.git
cd ~/Desktop/PopcornTimeTV
swift install.swift
```
Follow the instructions in the install sript to update your copy of PopcornTime. For all future updates, just run `swift install.swift` and it will walk you through the rest.

If the new install script is failing, revert to the old way and run `git checkout <release version>` and `pod update`

If you are installing PopcornTime for the first time run and are having issues try running
`pod install` otherwise if you are updating, run `pod update`.

If issues persist when installing TVVLC, remove the Pods folder and Podfile.lock and run this command in terminal `rm -rf ~/.cocoapods/repos/popcorntimetv`

Or you can find super easy [guide here](https://github.com/PopcornTimeTV/PopcornTimeTV/wiki/Building-PopcornTime)

**Open the project with**

PopcornTime.xcworkspace

##Screenshots

![Screenshots](http://i.cubeupload.com/usCzhQ.png)

##Want to help?

Join the project [Slack channel](http://popcorntimetv.herokuapp.com) and be part of the PopcornTime experience for AppleTV. Designer? Developer? Curious person? You're welcome! Come in and say hello. Want to report a bug, request a feature or even contribute? You can join our community Slack group to keep up-to-date and speak to the team.

If you plan on contributing, make sure to follow along with the guidelines found in the `CONTRIBUTING.md` file.
