//multi player
//for instructions see github/redFrik/biopump

/*
OSCFunc.trace(true);
OSCFunc.trace(false);
*/

(
//--setup:  EDIT HERE
var pushPulls= [
	//addr: ip and port of pushpull
	//strength: lower to something closer to zero for too-easy-to-pump instruments
	//isLeft: for left/right handed instruments
	(
		addr: NetAddr("192.168.2.1", 9000),  //pushpull 'gil'
		strength: 1.0,
		isLeft: false
	),
	(
		addr: NetAddr("192.168.2.2", 9000),  //pushpull '?'
		strength: 0.5,
		isLeft: false
	),
	(
		addr: NetAddr("192.168.2.6", 9000),  //pushpull '?'
		strength: 0.5,
		isLeft: false
	)
];

//--
var numChannels= pushPulls.size;  //should correspond with NUMCHANNELS in processing
var bufferSize= 735;  //should correspond with BUFFERSIZE in processing (1/60*44100)
s.latency= 0.025;
s.options.sampleRate= 44100;
s.waitForBoot{
	var processing= NetAddr("127.0.0.1", 47130);
	var accx= 0!numChannels;
	var pushPullAlphaTask;
	var pushPullAlpha= {|start, end, dur|
		pushPullAlphaTask.stop;
		pushPullAlphaTask= Routine.run({
			var steps= dur*25;  //25fps updaterate is enough here
			var step= (end-start)/steps;
			var lastVal= -1;
			steps.do{|i|
				var val= (start+(i*step)).asInteger;
				if(val!=lastVal, {
					processing.sendMsg(\alpha, val);
					lastVal= val;
				});
				(1/25).wait;
			};
			processing.sendMsg(\alpha, end);
		});
	};
	var reorder;
	var capCals= Array.newClear(numChannels);  //stores capacitive values for calibration
	var form, sections= 0!numChannels;
	var indexTime;  //for measuring how long cap4 been pressed
	var indexLast= -1;  //for filtering out repetitions
	var sectionsLast;
	var imuSyn, mainSyn;
	var synths= Array.newClear(numChannels), synthsLib;
	var waveBuffers= {Buffer.alloc(s, bufferSize, 1)}!numChannels;
	~waveBusses= {Bus.audio(s, 2)}!numChannels;
	~cxBus= Bus.control(s, numChannels);
	~cyBus= Bus.control(s, numChannels);
	~ampBus= Bus.control(s, numChannels);
	CmdPeriod.doOnce({
		waveBuffers.do{|x| x.free};
		~waveBusses.do{|x| x.free};
		{~cxBus.free; ~cyBus.free}.defer(0.5);
		~ampBus.free;
	});
	SynthDef(\waveTrk, {|in= 0, buf|
		var z= HPF.ar(Mix(In.ar(in, 2)), 9);
		var trig= Trig1.ar(HPZ1.ar(z>0).abs, 1/60);
		var phase= Sweep.ar(trig, SampleRate.ir);
		BufWr.ar(z, buf, phase, 0);
	}).add;
	s.sync;
	{|i|
		Synth(\waveTrk, [\buf, waveBuffers[i], \in, ~waveBusses[i]], s.defaultGroup, addAction:'addAfter');
	}!numChannels;
	Routine.run({
		inf.do{|i|
			i= i.asInteger%numChannels;
			waveBuffers[i].getn(0, bufferSize, {|data|
				processing.sendMsg(\waveData, *([i, ~cxBus.getnSynchronous[i], ~cyBus.getnSynchronous[i]]++data));
			});
			(1/60/numChannels).wait;
		};
	});
	imuSyn= {|ampx= 0, ampy= 0, lagx= 5, hp= 0.15|
		var x= \x.kr(0!numChannels);
		var y= \y.kr(0!numChannels)*\strengths.kr(1.0!numChannels);
		var xx= x.lag2(lagx);
		var yy= (HPF.kr(y, hp, 3).abs.lag2ud(15, 50)-0.02).clip(0, 1);  //was lag2ud(10, 40)
		Out.kr(~cxBus, xx*ampx.lag(10)*(yy*2).clip(0, 1));
		Out.kr(~cyBus, yy*ampy.lag(10));
		Out.kr(~ampBus, (yy*2).tanh);  //amplitudes for all synths - scale here
	}.play;
	s.sync;
	imuSyn.set(\strengths, {|i| pushPulls[i].strength}!numChannels);
	numChannels.do{|index|
		OSCdef(("imu"++index).asSymbol, {|msg|
			var accRawVals= msg[4..6];
			//[index, accRawVals].postln;  //debug
			accx[index]= accRawVals[0];
			imuSyn.set(\x, accx, \y, (0!numChannels).put(index, accRawVals[2]-0.9));
		}, '/imu', pushPulls[index].addr);
	};
	numChannels.do{|index|
		reorder= if(pushPulls[index].isLeft, {#[1, 2, 3, 0, 4, 5]}, {#[0, 3, 2, 1, 4, 5]});
		OSCdef(("caps"++index).asSymbol, {|msg|
			var str= "", capRawVals;
			msg[1].do{|c| str= str++c.asAscii};
			capRawVals= str.split(Char.space).asInteger;
			capRawVals= capRawVals[reorder];
			if(capCals[index].isNil, {
				capCals[index]= capRawVals;  //read offset at startup
			}, {
				i= (((capRawVals-capCals[index])/16383)>0.01).indexOf(true);
				//[index, i].postln;  //debug
				if(i!=indexLast, {
					if(i==4 and:{indexLast!=4}, {
						pushPulls[index].addr.sendMsg('/outputs/rgb/1', {#[0, 255, 0]}.dup(8).flat.as(Int8Array));  //all green
					});
					if(i.isNil and:{indexLast==4}, {
						if(Main.elapsedTime-indexTime>2, {  //hold cap4 to switch sound
							sections.put(index, sections[index]+1);
							form.value(index);
							pushPulls[index].addr.sendMsg('/outputs/rgb/1', 255.dup(24).as(Int8Array));  //all white
							{
								pushPulls[index].addr.sendMsg('/outputs/rgb/1', Int8Array.newClear(24));  //all black
							}.defer(1);
						}, {
							pushPulls[index].addr.sendMsg('/outputs/rgb/1', Int8Array.newClear(24));  //all black
						});
					});
					indexLast= i;
					indexTime= Main.elapsedTime;
				});
			});
		}, '/inputs/serial/1', pushPulls[index].addr);
	};

	synthsLib= [
		[
			{var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(198.5*(a.ar(0.08,0.5).range(0.5, 1.5).round(0.333))+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9]*1.1)).lag(f/4)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[0])},  //t0270
			{var a,b,c; a=SinOsc;b=(a.ar(c=0.015)/9<a.ar(5/(1..7))).varlag(c);LeakDC.ar(Splay.ar(a.ar(2-b**ceil(a.ar(b)*5+(a.ar(0.01).round+5))+2,b)+BrownNoise.ar(b%1)).sin*0.75).softclip*(In.kr(~ampBus, 3)[0])},  //t0271
			{var a,c,d; a=LFSaw;(Pan2.ar(AllpassC.ar(a.ar(1/c=(1..6))>0.95*a.ar((d=a.ar(0.075))>0/3+1*c*99*0.5),c/9,c/9,d*4+1),a.ar(1/c/9*2)).sum.lag*12).softclip*(In.kr(~ampBus, 3)[0])}  //t0245
		],
		[
			{var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(98.5+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9])).lag(f/9)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[1])},  //t0270
			{var a,b,c; a=SinOscFB;c=a.ar(#[50,99],0.4);RecordBuf.ar(InFeedback.ar(0,2)+c/3,b=LocalBuf(8e4,2).clear);BufRd.ar(2,b,a.ar(c)*6e4).mean*(In.kr(~ampBus, 3)[1])}  //t0160
		],
		[
			{var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(298.5*(a.ar(0.1,0.5).range(0.5, 2).round(0.333))+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9]*0.9)).lag(f/9)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[2])},  //t0270
			{var a,c,d; a=LFSaw;(Pan2.ar(AllpassC.ar(a.ar(1/c=(1..9))>0.9*a.ar((d=a.ar(0.075))>0/3+1*c*99),c/9,c/9,d*4+4),a.ar(1/c/9)).sum.lag*12).softclip*(In.kr(~ampBus, 3)[2])},  //t0245
			{var a,b,c; a=SinOscFB;c=a.ar(#[50,99],0.4);RecordBuf.ar(InFeedback.ar(0,2)+c/3,b=LocalBuf(8e4,2).clear);BufRd.ar(2,b,a.ar(c)*6e4).mean*(In.kr(~ampBus, 3)[2])}  //t0172
		]
	];

	form= {|index|
		("index:"+index++", form sections are now:"+sections).postln;
		if(sectionsLast.isNil, {
			mainSyn= {Limiter.ar(LeakDC.ar(Mix.fill(numChannels, {|i| In.ar(~waveBusses[i], 2)})))}.play(addAction:\addToTail);
			processing.sendMsg(\feedback, 0);
			processing.sendMsg(\alpha, 50);
		}, {
			sections.do{|section, i|
				if(sectionsLast[i]!=section, {
					synths[i].release(30);
					synths.put(i, synthsLib[index].wrapAt(section-1).play(outbus:~waveBusses[index], fadeTime:30));
				});
			};
			switch(sections.sum,
				1, {
					"starting".postln;
					imuSyn.set(\ampx, 6pi, \ampy, 6pi);
				},
				4, {
					"increasing alpha and lowering lagx".postln;
					pushPullAlpha.value(50, 255, 60);
					imuSyn.set(\lagx, 4);
				},
				5, {
					"starting feedback and lowering alpha".postln;
					processing.sendMsg(\feedback, 1);
					pushPullAlpha.value(255, 20, 120);
				},
				7, {
					"lowering alpha more".postln;
					pushPullAlpha.value(20, 5, 120);
				},
				8, {
					"last setting - lots of trails".postln;
					pushPullAlpha.value(5, 3, 100);
				}
			);
		});
		sectionsLast= sections.copy;
	};
	form.value(0);

	//--debug interface
	~form= {|i| form.value(i)};
	~sections= {|i, j| sections.put(i, j)};
	~imu= imuSyn;
};
)

/*
//--testing
s.scope
s.scope(rate:\control)

~imu.free;  //mute input from pushpull
~sections.value(0, 1); ~form.value(0)
~ampBus.setn([0.33, 0.33, 0.33])
~cyBus.setn([pi, pi, pi])
~sections.value(1, 2); ~form.value(1)
~sections.value(2, 3); ~form.value(2)
~ampBus.setn([0, 0.2, 0])  //one line only
~cyBus.setn([1, 1, 1]*100)  //very long lines

~imu.set(\x, [0.5, 0.4, 0.3], \y, [0.8, 0.7, 0.6]);  //for testing
~imu.set(\strengths, [0.2, 0.3, 0.4])  //lower makes it harder to pump
n= NetAddr("127.0.0.1", 47130);  //processing
n.sendMsg(\feedback, 0);
n.sendMsg(\feedback, 1);
n.sendMsg(\alpha, 10)
n.sendMsg(\alpha, 100)
n.sendMsg(\alpha, 255)
*/
