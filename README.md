#OpenPlayer for iOS

OpenPlayer is an Objective C library developed by AudioNow Digital, for playing OPUS and VORBIS audio files in your mobile applications. 

You can use it for playing local files or network streams.

OpenPlayer delivers great performance, by using native codec implementation. It has been designed to decode OPUS and VORBIS content within an OGG Wrapper.


#Quick Start

Run OpenPlayerDemo scheme to see an example of usage.

Build library with BuildOpenPlayer scheme. Take library from products folder and import it in your project.

You need a IPlayerHandler object to handle the media events comming from library.

**1 To create an OpenPlayer instance, use:**

`OpenPlayer *player = [[OpenPlayer alloc] initWithPlayerHandler:playerHandler typeOfPlayer:PLAYER_OPUS enableLogs:NO];`

**2 To initialize the player with a VORBIS or OPUS source, use:**

`[player setDataSource:url withSize:FILE_LENGTH_SECONDS];`

**Note:** FILE_LENGTH_SECONDS is necessary for media files, for computing progress and allowing media seek. If you are decoding a live stream, you will need to use FILE_LENGTH_SECONDS = -1.

**3 The IPlayerHandler object needs to implement the following method to respond to events comming from the library**

`-(void)onPlayerEvent:(PlayerEvent) event withParams:(NSDictionary *)params;`


#Player Events
OpenPlayer is an event-based library. The events that will be fired in the decoding process are the following:

-  `READING_HEADER` - triggered when the library starts to read the OGG header of the stream
-  `TRACK_INFO` - while reading the OGG Header, the library will parse track information. This event is triggered when track information is available.
-  `READY_TO_PLAY` - called after the stream has been prepared. At this point, you can call `player.play()` in order to start playback
-  `PLAY_UPDATE` - use this trigger for play progress
-  `PLAYING_FAILED` - there has been a problem while decoding the stream.
-  `PLAYING_FINISHED` - player reached the end of the stream


#Android Version
OpenPlayer has also been developed for Android platform. You can find it here:

https://github.com/audionowdigital/openplayer-android


License
-------

© 2014 AudioNow® Digital, LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.