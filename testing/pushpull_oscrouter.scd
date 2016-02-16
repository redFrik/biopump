//for forwarding osc messages from a pushpull to a main laptop on another network.
//connect a second laptop (running this code) to two networks: airport & ethernet.
//the main laptop is on the same airport, the pushpull instrument on the ethernet.

/*
OSCFunc.trace(true);
OSCFunc.trace(false);
*/

(
var from= NetAddr("192.168.2.6", 9000);  //ip of pushpull
var to= NetAddr("192.168.1.53", 9000);  //ip of main laptop
OSCdef(\oscrouterCaps, {|msg|
	//msg.postln;  //debug
	to.sendMsg(*msg);
}, '/imu', from);
OSCdef(\oscrouterImu, {|msg|
	//msg.postln;  //debug
	to.sendMsg(*msg);
}, '/inputs/serial/1', from);
)

//test on the receiver (to) laptop
/*
OSCdef(\caps, {|msg| msg.postln}, '/inputs/serial/1', recvPort:9000);
OSCdef(\imu, {|msg| msg.postln}, '/imu', recvPort:9000);
*/
