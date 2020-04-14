<p align="left " >
  <img src="http://i.imgur.com/76RElTT.png" alt="Popcorn Time" title="Popcorn Time">
</p>

# Popcorn Time for tvOS and iOS  (iOS 13 fixes & more!)

## Download

Download the [latest .ipas](https://github.com/PopcornTimeTV/PopcornTimeTV/releases/latest).

Alternatively you can [compile one yourself](https://github.com/PopcornTimeTV/PopcornTimeTV/wiki/Archiving-Popcorn-Time).

Once downloaded, follow our [Installing Guide](https://github.com/PopcornTimeTV/PopcornTimeTV/wiki/Installing-Popcorn-Time).

## Know what you're doing?

First, you need to install [bundler](https://bundler.io) to your computer with the `gem install bundler` command.

Then you can use [CocoaPods](http://cocoapods.org/) to install dependencies.

Build instructions:

``` bash
$ git clone https://github.com/PopcornTimeTV/PopcornTimeTV.git
$ cd PopcornTimeTV/
$ bundle install
$ bundle exec pod repo update
$ bundle exec pod install
$ open PopcornTime.xcworkspace
```
## License

If you distribute a copy or make a fork of the project, you have to credit this project as source.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/.

Note: some dependencies are external libraries, which might be covered by a different license compatible with the GPLv3. They are mentioned in [NOTICE.md](https://github.com/PopcornTimeTV/PopcornTimeTV/blob/master/NOTICE.md).


**This project and the distribution of this project is not illegal, nor does it violate _any_ DMCA laws. The use of this project, however, may be illegal in your area. Check your local laws and regulations regarding the use of torrents to watch potentially copyrighted content. The maintainers of this project do not condone the use of this project for anything illegal, in any state, region, country, or planet. _Please use at your own risk_.**

***

Copyright (c) 2017 Popcorn Time Foundation - Released under the [GPL V3 license](https://github.com/PopcornTimeTV/PopcornTimeTV/LICENSE.md).
