OSCFunc.trace(true)
OSCFunc.trace(false)

OSCdef(\imu, {|msg| msg.postln}, 'imu')
OSCdef(\inputs, {|msg| msg.postln}, 'inputs/serial/1')

p= NetAddr("192.168.2.6", 9000)
p.sendMsg(\ping)


//--discover osc
(
~dict= ();
~func= {|msg, time, addr, recvPort|
	var tag= msg[0];
	if(~dict[tag].isNil, {
		"OSC Message Received:\n\taddress: %\n\trecvPort: %\n\tmsg: %\n\n".postf(addr, recvPort, msg);
		~dict.put(tag, (
			addr: addr,
			tag: msg[0],
			msg: msg
		));
	});
};
thisProcess.addOSCRecvFunc(~func);
CmdPeriod.doOnce({thisProcess.removeOSCRecvFunc(~func)});
)
~dict.keys  //addresses of devices that have sent data


//--leds
c= [Color.red, Color.blue, Color.green].scramble.wrapExtend(8).collect{|c| c.asArray.keep(3)*255}.flat.as(Int8Array);
p.sendMsg('/outputs/rgb/1', c);
c= Int8Array.fill(24, 0);
p.sendMsg('/outputs/rgb/1', c);

(
~index= 0;  //which led pwm channel to test
Routine.run({
	inf.do{|i|
		var pwm= Array.fill(12, 0);
		pwm[~index.clip(0, 11)]= sin(i*0.1).linlin(-1, 1, 0, 255);
		p.sendMsg('/outputs/rgb/1', pwm.as(Int8Array));
		(1/60).wait;
	};
});
)
~index= 1  //green1
~index= 4  //green2
~index= 7  //green3
~index= 10 //green4


//--capacitive sensors
s.boot
s.scope(6, rate:\control)
(
var isLeft= false;
var numCap= 6;
var capBus= Bus.control(s, numCap);
var capSynth= {|lag= 0.1, thresh= 0.01| Out.kr(capBus.index, \cap.kr(0!numCap, lag)>thresh)}.play;
var capCal;
CmdPeriod.doOnce({capBus.free});
OSCdef(\caps, {|msg|
	var str= "", capRawVals;
	msg[1].do{|c| str= str++c.asAscii};
	capRawVals= str.split(Char.space).asInteger;
	if(isLeft, {
		capRawVals= capRawVals[#[1, 2, 3, 0, 4, 5]];
	}, {
		capRawVals= capRawVals[#[0, 3, 2, 1, 4, 5]];
	});
	if(capCal.isNil, {
		capCal= capRawVals;  //read offset at startup
	}, {
		capSynth.set(\cap, (capRawVals-capCal)/16383);
	});
}, '/inputs/serial/1', p);
)


//--accelerometer
s.boot
s.scope(3, rate:\control)
(
var accBus= Bus.control(s, 3);
var accSynth= {|lag= 0.1, hp= 0.15| var a= \acc.kr(0!3, lag); Out.kr(accBus.index, [a[0], a[1], HPF.kr(a[2], hp)])}.play;
CmdPeriod.doOnce({accBus.free});
OSCdef(\imu, {|msg|
	var accRawVals= msg[4..6];
	//accRawVals.postln;
	accSynth.set(\acc, accRawVals);
}, '/imu', p);
)


//--gyroscope
s.boot
s.scope(3, rate:\control)
(
var gyroBus= Bus.control(s, 3);
var gyroSynth= {|lag= 0.1| Out.kr(gyroBus.index, \gyro.kr(0!3, lag))}.play;
CmdPeriod.doOnce({gyroBus.free});
OSCdef(\imu, {|msg|
	var gyroRawVals= msg[1..3];
	//gyroRawVals.postln;
	gyroSynth.set(\gyro, gyroRawVals*0.01);
}, '/imu', p);
)

/*
imuDict[\gyro] = msg[1..3];
imuDict[\acc] = msg[4..6];
imuDict[\mag] = msg[7..9];
imuDict[\normedMag] = ((msg[7..9] - direction) % 2pi) - pi;
imuDict[\temp] = msg[10];
*/


//--stuff
a= PushPullOSC_SE(NetAddr("192.168.2.6", 9000))
a.setLight(Color.red)
a.imuDict.keys
a.imuDict[\acc]
a.imuDict[\mag]
a.imuDict[\gyro]
a.imuDict[\temp]
a.imuDict[\normedMag]
a.imuDict[\a]  //?
a.imuDict[\m]  //?
a.imuDict[\t]  //?
a.imuDict[\g]  //?
a.isLeft
a.tareMag; a.direction
a.capRawVals
a.capNormVals
a.capTrigs
a.capMinMax
