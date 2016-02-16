# biopump

A piece for 3DMIN's PushPull instrument

## Background

This interactive audiovisual composition was commissioned by [3DMIN](http://3dmin.org) and supported by the festival/conference [GLOBALE: Performing Sound, Playing Technology](http://zkm.de/event/2016/02/globale-performing-sound-playing-technology). It was premiered 2016-02-05 in Karlsruhe at the ZKM Kubus.

This is a piece for the [PushPull](http://www.3dmin.org/research/open-development-and-design/pushpull/) instrument and works a bit like a game where the performer(s) need to pump up the sound - and keep on pumping for the piece to develop. If played by a single person the performer has to select which sounds to keep breeding. When multiple people perform the piece they get to pump one sound each. All sounds and graphics are generated in realtime.

![biopump_screenshot.png](biopump_screenshot.png?raw=true "biopump_screenshot.png")

## Requirements

* Fast OSX laptop (10.10.5 but should also run under later/earlier and on Linux/Windows (untested))
* PushPull instrument with WiFi router
* Stereo sound system (with subbass preferred)
* Video projection (1080p resolution preferred)
* [SuperCollider](http://supercollider.github.io) (v3.7 with no special extensions)
* [Processing](http://processing.org) (v3 with the OscP5 library)

## Installation

* The Supercollider code is written to work on the default sc3.7 without the need to install any extra classes or plugins.
* The Processing code needs the OscP5 library. Install it from inside Processing ifself: under menu 'Add Tool...' search for 'oscp5' among the libraries.

## Startup

* On the laptop: turn off f.lux, screensaver, 'automatic graphics switching' in OSX system preferences etc.
* Set up the network, connect the laptop to the WiFi router and turn on the PushPull instrument.
* Connect a video projector and sound to the laptop.
* Open and run the sketch `biopump_graphics.pde` in Processing. It should display fullscreen black with a few green dots.
* Start SuperCollider and run the code in either `biopump_singleplayer.scd` or `biopump_multiplayer.scd`.
* The capacitive sensors are calibrated at startup so do not touch them at the same time as you start the SuperCollider code.

## Single player

* Select which channel (line) to pump up with capacitive sensors 1-3.
* Pump and jump between channels - find interesting sounds.
* Go to next form section by holding capacitive sensor 4 for longer than 2 seconds.
* There are seven form sections in total...
  0. silent - waiting for piece to start
  1. sound fading in - start pumping to hear and see a sound - slowly
  2. sound changing on first channel
  3. sound changing on third channel - feedback in graphics slowly starting
  4. sound changing on first and second channel - more alpha and feedback graphics
  5. sound changing on third channel and first fading out - even more alpha
  6. sound fading out to silence - piece ends.
* Tilt the head of the PushPull instrument to move the selected line left and right.

## Multi player

* The players control one channel (line) each.
* Pump to hear and see sound.
* Select new sound by holding capacitive sensor 4 for longer than 2 seconds.
* Tilt the head of the PushPull instrument to move the line left and right.

## Future ideas

* implement collision detection for lines (in Processing and send back data via osc).

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">biopump</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="http://www.fredrikolofsson.com" property="cc:attributionName" rel="cc:attributionURL">Fredrik Olofsson</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.<br />Based on a work at <a xmlns:dct="http://purl.org/dc/terms/" href="http://github.com/redFrik/biopump" rel="dct:source">github.com/redFrik/biopump</a>.