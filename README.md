# biopump

A piece for 3DMIN's PushPull instrument

## Background

This interactive audiovisual composition was commissioned by ZKM | Institute for Music and Acoustics for the festival/conference [GLOBALE: Performing Sound, Playing Technology](https://zkm.de/event/2016/02/globale-performing-sound-playing-technology). It was premiered 2016-02-05 in Karlsruhe at the ZKM Kubus.

It was written for [3DMIN](https://3dmin.org)'s [PushPull](https://www.3dmin.org/research/open-development-and-design/pushpull/) instrument and works a bit like a game where the performer(s) need to **pump up the sound** - and keep on pumping for the piece to develop. If played by a single person the performer has to select which sounds to keep breeding. When multiple people perform the piece they get to pump one sound channel each. All sounds and graphics are generated in realtime.

![biopump_screenshot.png](biopump_screenshot.png?raw=true "biopump_screenshot.png")

## Requirements

* Fast OSX laptop (10.10.5 but should also run under later/earlier and on Linux/Windows (untested))
* PushPull instrument with WiFi router
* Stereo sound system (with subbass preferred)
* Video projection (1080p resolution preferred)
* [SuperCollider](https://supercollider.github.io) (v3.7 with no special extensions)
* [Processing](https://processing.org) (v3 with the OscP5 library)

## Installation & Startup

* The Processing code needs the OscP5 library. Install it from inside Processing itself: under menu *Add Tool...* search for *oscp5* among the libraries.
* On the laptop: turn off f.lux, screensaver, automatic graphics switching in OSX system preferences etc.
* Set up the network, connect the laptop to the WiFi router and turn on the PushPull instrument.
* Connect a video projector and sound to the laptop.
* Open and run the sketch `biopump_graphics.pde` in Processing. It should display fullscreen black with a few green dots.
* Start SuperCollider and run the code in either `biopump_singleplayer.scd` or `biopump_multiplayer.scd`.
* The capacitive sensors are calibrated at startup so do not touch them at the same time as you evaluate the SuperCollider code.

## Single player

* Select which channel (line) to pump up with capacitive sensors 1-3.
* Pump and jump between channels - find interesting sounds.
* Go to next form section by holding capacitive sensor 4 for longer than 2 seconds.
* There are seven form sections in total...
  * silent - waiting for the piece to start
  * sound fading in - start pumping to hear and see a sound - slowly
  * sound changing on the first channel
  * sound changing on the third channel - feedback in graphics slowly starting
  * sound changing on the first and second channel - more alpha and feedback graphics
  * sound changing on the third channel and first fading out - even more alpha
  * sound fading out to silence - piece ends.
* Tilt the head of the PushPull instrument to move the selected line left and right.

## Multiplayer

* The players control one channel (line) each.
* Select new sound by holding capacitive sensor 4 for longer than 2 seconds.
* Pump to hear and see your sound.
* Tilt the head of the PushPull instrument to move the line left and right.

## Duration

* The piece can last for a few minutes up to around 10 minutes. It is up to the performers to judge.

## Future ideas

* Implement collision detection for lines (in Processing and send back data via OSC).
* Tune strength using one of the knobs at the instrument base.

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">biopump</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://www.fredrikolofsson.com" property="cc:attributionName" rel="cc:attributionURL">Fredrik Olofsson</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.<br />Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="http://github.com/redFrik/biopump" rel="dct:source">github.com/redFrik/biopump</a>.