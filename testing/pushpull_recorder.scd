//record caps and imu
(
var startTime= Main.elapsedTime;
~recImu= List.new;
~recCap= List.new;
OSCdef(\imu, {|msg|
	~recImu.add([Main.elapsedTime-startTime, msg].postln);
}, '/imu', p);
OSCdef(\caps, {|msg|
	~recCap.add([Main.elapsedTime-startTime, msg].postln);
}, '/inputs/serial/1', p);
)


//save data to disk
[~recImu, ~recCap].writeArchive("~/biopump/utilities/pp.scd".standardizePath)

//read back data from disk
(
var a= Object.readArchive("~/biopump/utilities/pp.scd"standardizePath);
~recImu= a[0];
~recCap= a[1];
)


//playback
(
var net= NetAddr.localAddr;
Routine.run({
	var nowTime= 0;
	~recImu.do{|x|
		(x[0]-nowTime).wait;
		nowTime= x[0];
		net.sendMsg(x[1][0], *x[1][1..]);
	};
	"done recImu".postln;
});
Routine.run({
	var nowTime= 0;
	~recCap.do{|x|
		(x[0]-nowTime).wait;
		nowTime= x[0];
		net.sendMsg(x[1][0], *x[1][1..]);
	};
	"done recCap".postln;
});
)

//test
(
OSCdef(\recImu, {|msg|
	msg.postln;
}, '/imu');
OSCdef(\recCap, {|msg|
	msg.postln;
}, '/inputs/serial/1');
)
