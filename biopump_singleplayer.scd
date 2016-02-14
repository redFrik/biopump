//for zkm, karlsruhe, 5feb2016

//turn off f.lux, screensaver, automatic gpu switch, airport

OSCFunc.trace(true);
OSCFunc.trace(false);

(
//--setup:
var pushPull= NetAddr("192.168.2.6", 9000);  //pushpull 'gil'
//var pushPull= NetAddr("127.0.0.1", 9000);  //for testing
var isLeft= false;
var numChannels= 3;  //should correspond with NUMCHANNELS in processing
var bufferSize= 735;  //should correspond with BUFFERSIZE in processing (1/60*44100)

//--server:
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
	var capCal;  //stores capacitive values for calibration
	var form, section= 0;
	var indexTime;  //for measuring how long cap4 been pressed
	var indexLast= -1;  //for filtering out repetitions
	var index= 1;  //default channel to control
	var imuSyn, mainSyn;
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
	imuSyn= {|ampx= 6pi, ampy= 6pi, lagx= 5, hp= 0.15|
		var x= \x.kr(0!numChannels);
		var y= \y.kr(0!numChannels);
		var xx= x.lag2(lagx);
		var yy= (HPF.kr(y, hp, 3).abs.lag2ud(15, 50)-0.02).clip(0, 1);  //was lag2ud(10, 40)
		Out.kr(~cxBus, xx*ampx.lag(10)*(yy*2).clip(0, 1));
		Out.kr(~cyBus, yy*ampy.lag(10));
		Out.kr(~ampBus, (yy*2).tanh);  //amplitudes for all synths - scale here
	}.play;
	OSCdef(\imu, {|msg|
		var accRawVals= msg[4..6];
		//accRawVals.postln;  //debug
		accx[index]= accRawVals[0];
		imuSyn.set(\x, accx, \y, (0!numChannels).put(index, accRawVals[2]-0.9));
	}, '/imu', p);
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
			i= (((capRawVals-capCal)/16383)>0.01).indexOf(true);
			if(i!=indexLast, {
				if(i.notNil and:{i<numChannels}, {
					index= i;
					pushPull.sendMsg('/outputs/rgb/1', [Color.green, Color.black, Color.black].rotate(i).wrapExtend(8).collect{|c| c.asArray.keep(3)*255}.flat.as(Int8Array));
				}, {
					if(i.isNil and:{indexLast==4}, {
						if(Main.elapsedTime-indexTime>2, {  //hold cap4 to go to next section
							section= section+1;
							form.value();
						});
					});
					pushPull.sendMsg('/outputs/rgb/1', Int8Array.newClear(24));  //all black
				});
				indexLast= i;
				indexTime= Main.elapsedTime;
			});
		});
	}, '/inputs/serial/1', p);
	form= {
		("form section is now:"+section).postln;
		switch(section,
			0, {
				mainSyn= {Limiter.ar(LeakDC.ar(Mix.fill(numChannels, {|i| In.ar(~waveBusses[i], 2)})))}.play(addAction:\addToTail);
				processing.sendMsg(\feedback, 0);
				processing.sendMsg(\alpha, 50);
			},
			1, {
				~ch0.release;
				~ch0= {var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(198.5*(a.ar(0.08,0.5).range(0.5, 1.5).round(0.333))+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9]*1.1)).lag(f/4)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[0])}.play(outbus:~waveBusses[0], fadeTime:10);  //t0270
				~ch1.release;
				~ch1= {var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(98.5+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9])).lag(f/9)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[1])}.play(outbus:~waveBusses[1], fadeTime:10);    //t0270
				~ch2.release;
				~ch2= {var a,c,d,f; a=SinOscFB;AllpassN.ar(a.ar(298.5*(a.ar(0.1,0.5).range(0.5, 2).round(0.333))+c=(Amplitude.ar(d=InFeedback.ar)<a.ar(f=1/#[9,8.9]*0.9)).lag(f/9)+d,d+f,c),f*3,f*3,20).tanh*0.5*(In.kr(~ampBus, 3)[2])}.play(outbus:~waveBusses[2], fadeTime:10);    //t0270
			},
			2, {
				pushPullAlpha.value(50, 255, 60);
				imuSyn.set(\lagx, 4);
				~ch0.release(30);
				~ch0= {var a,b,c; a=SinOsc;b=(a.ar(c=0.015)/9<a.ar(5/(1..7))).varlag(c);LeakDC.ar(Splay.ar(a.ar(2-b**ceil(a.ar(b)*5+(a.ar(0.01).round+5))+2,b)+BrownNoise.ar(b%1)).sin*0.75).softclip*(In.kr(~ampBus, 3)[0])}.play(outbus:~waveBusses[0], fadeTime:50);  //t0271
			},
			3, {
				processing.sendMsg(\feedback, 1);
				pushPullAlpha.value(255, 20, 120);
				~ch2.release(30);
				~ch2= {var a,c,d; a=LFSaw;(Pan2.ar(AllpassC.ar(a.ar(1/c=(1..9))>0.9*a.ar((d=a.ar(0.075))>0/3+1*c*99),c/9,c/9,d*4+4),a.ar(1/c/9)).sum.lag*12).softclip*(In.kr(~ampBus, 3)[2])}.play(outbus:~waveBusses[2], fadeTime:30);  //t0245
			},
			4, {
				pushPullAlpha.value(20, 5, 120);
				~ch00.release(30);
				~ch00= {var a,c,d; a=LFSaw;(Pan2.ar(AllpassC.ar(a.ar(1/c=(1..6))>0.95*a.ar((d=a.ar(0.075))>0/3+1*c*99*0.5),c/9,c/9,d*4+1),a.ar(1/c/9*2)).sum.lag*12).softclip*(In.kr(~ampBus, 3)[0])}.play(outbus:~waveBusses[0], fadeTime:20);  //t0245
				~ch1.release(60);
				~ch1= {var a,b,c; a=SinOscFB;c=a.ar(#[50,99],0.4);RecordBuf.ar(InFeedback.ar(0,2)+c/3,b=LocalBuf(8e4,2).clear);BufRd.ar(2,b,a.ar(c)*6e4).mean*(In.kr(~ampBus, 3)[1])}.play(outbus:~waveBusses[1], fadeTime: 30);  //t0160
				/*
				~ch1= {var a,b; a=LFPulse;LeakDC.ar(
					LPF.ar(
					SinOsc.ar(MouseX.kr(40, 60).poll+[0,1],0,MouseY.kr(0, 1))*Splay.ar(a.ar((99*b=#[1,4,5,8])*lag(a.ar(a.ar(4/b)+a.ar(9-b/9)*50))+b)/2)
					,4000)
				)+Mix(GrayNoise.ar(a.ar(b,0,0.1))*0.15)*(In.kr(~ampBus, 3)[1])}.play(outbus:~waveBusses[1], fadeTime:10);  //t0234
				*/
				/*
				~ch1.release(10);
				~ch1= {var a,b,c,z; a=Blip;b=9/(1..9);c=a.ar(b/9,2);z=sum(a.ar(b,303)*a.ar(b/5-4,2.5));{|i|z=z+AllpassC.ar(z,i+1/b/9,i+1/b/9,c,b/9)}!9;Splay.ar(z.sin*0.5).softclip*(In.kr(~ampBus, 3)[1])!2}.play(outbus:~waveBusses[1], fadeTime:10);  //t0267
				*/
			},
			5, {
				pushPullAlpha.value(5, 3, 100);
				~ch0.release(20);
				~ch2.release(30);
				~ch2= {var a,b,c; a=SinOscFB;c=a.ar(#[50,99],0.4);RecordBuf.ar(InFeedback.ar(0,2)+c/3,b=LocalBuf(8e4,2).clear);BufRd.ar(2,b,a.ar(c)*6e4).mean*(In.kr(~ampBus, 3)[2])}.play(outbus:~waveBusses[2], fadeTime: 20);  //t0172
			},
			6, {
				~ch00.release(15);
				~ch1.release(15);
				~ch2.release(15);
				mainSyn.release(25);
			}
		);
	};
	form.value;

	//--debug interface
	~form= form;
	~section= {|i| section= i};
	~imu= imuSyn;
	~index= {|i| index= i};
};
)

/*
s.scope
s.scope(rate:\control)
~section.value(1); ~form.value
~section.value(2); ~form.value
~section.value(3); ~form.value
~section.value(4); ~form.value
~section.value(5); ~form.value

~imu.free;
~ampBus.setn([0.33, 0.33, 0.33])

~ampBus.setn([0, 0.2, 0])

~cyBus.setn([1, 1, 1]*100)
~index.value(1)
~imu.set(\x, [0.5, 0.4, 0.3], \y, [0.8, 0.7, 0.6]);
n= NetAddr("127.0.0.1", 47130);
n.sendMsg(\feedback, 0);
n.sendMsg(\feedback, 1);
n.sendMsg(\alpha, 10)
n.sendMsg(\alpha, 100)
n.sendMsg(\alpha, 255)
*/
