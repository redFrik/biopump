g= NetAddr("127.0.0.1", 47130);  //processing


//format: [channel_index, accel_x, accel_y, sound_samples...]
(
~index= 0;  //which channel to test
~ax= 0.25;  //width
~ay= pi;    //height (pi= max before folding back)
Routine.run({
	inf.do{|i|
		var fake= {|j| sin(j*0.01+(i*0.03))}!735;
		g.sendMsg(\waveData, ~index, ~ax.asFloat, ~ay.asFloat, *fake);
		(1/60).wait;
	};
});
)
~index= 1;
~index= 2;
~index= 0;

~ax= 1.0;
~ax= 10.0;
~ay= pi*0.5;
~ay= pi*4;



//format: [alpha(0-255)] where 255 is off (no trails)
g.sendMsg(\alpha, 4);  //a lot of trails
g.sendMsg(\alpha, 20);  //medium
g.sendMsg(\alpha, 255);  //off

//format: [feedback(0|1)]
g.sendMsg(\feedback, 1);  //on
g.sendMsg(\alpha, 20);  //needs some alpha
g.sendMsg(\feedback, 0);  //off
