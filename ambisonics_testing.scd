s.boot;
FoaDecoderMatrix.newDirections([-22.5, 22.5, -67.5, 67.5, -112.5, 112.5, -157.5, 157.5].degrad)

FoaDecoderMatrix.newDiametric([-22.5, 22.5, -67.5, 67.5].degrad)

/* encoding a plane wave, and routing to a single decoder: */

s.options.numOutputBusChannels_(8)
s.boot;

s.makeGui
(
~foaBus = Bus.audio(s, 8); // allocate four channels for routing

//encodings
//w proximity
SynthDef(\foaPanB, {arg outBus, duration = 0.05, theta, phi, distance;
    var src, foa, encoder;
    var freq = 20.0;
    src = PinkNoise.ar(-6.dbamp * 1!8) *
        EnvGen.kr(
            Env([0, 1, 0], [0.5, 0.5], \sin),
            timeScale: duration,
            doneAction: 2);
    foa = FoaPanB.ar(src, theta, phi);

    //transform
    foa = HPF.ar(foa, freq);
    foa = FoaTransform.ar(foa, 'proximity', distance );
    Out.ar(outBus, foa);
}).add;

SynthDef(\foaDecor, {
    arg outBus, duration = 0.05, angle = pi/2;
    var src, foa, encoder;
    src = PinkNoise.ar(-6.dbamp * 1!8) *
        EnvGen.kr(
            Env([0, 1, 0], [0.5, 0.5], \sin),
            timeScale: duration,
            doneAction: 2);
    foa = FoaEncode.ar(src, FoaEncoderMatrix.newAtoB);
    foa = FoaTransform.ar(foa, 'pushX', angle);
    Out.ar(outBus, foa);
}).add;


//spread
//must execute this first to give kernel time to load
//~encoder = FoaEncoderKernel.newSpread;
//try with more natural recordings
SynthDef(\foaSpread, {
    arg outBus, dur = 0.05, amp = 0.25, angle =0, theta = 0, phi = 0;
    var src, foa, encoder;
    src = PinkNoise.ar(amp) *
        EnvGen.kr(
            Env([0, 1, 0], [0.5, 0.5], \sin),
            timeScale: dur,
            doneAction: 2);
    foa = FoaEncode.ar(src, ~encoder);
    foa = FoaTransform.ar(foa, 'focus', angle, theta, phi);
    Out.ar(outBus, foa);
}).add;

//diffuse
//must execute this first to give kernel time to load
//~encoder = FoaEncoderKernel.newDiffuse;
// try rotation here
SynthDef(\foaDiffuse, {arg outBus, dur = 0.05, amp = 0.25;
    var src, foa, encoder;
    src = PinkNoise.ar(amp) *
        EnvGen.kr(
            Env([0, 1, 0], [0.5, 0.5], \sin),
            timeScale: dur,
            doneAction: 2);
    foa = FoaEncode.ar(src, ~encoder);
    Out.ar(outBus, foa);
}).add;

//granular synthesis in B format, try this with waveloss synth
SynthDef(\foaDust, {arg outBus, dur = 0.05, amp = 0.125, density = 10.0;
    var src, foa;
    var loFreq = 100.0, hiFreq = 5000, klankArgs;

    klankArgs = Ref([[800, 1071, 1153, 1723], nil, dur/20 * [1, 1, 1, 1]]);

    src = Dust.ar(density * [1, 1, 1, 1] / 4, amp);
    src = Klank.ar(klankArgs, src);

    src = LPF.ar(src,
      EnvGen.kr(Env([loFreq, hiFreq, loFreq], [0.1, 0.9], \exp), timeScale: dur),
      EnvGen.kr(Env([0, 1, 0], [0.1, 0.9], \sin), timeScale: dur)
    );

    foa = FoaEncode.ar(src, FoaEncoderMatrix.newAtoB('fbd'));
    Out.ar(outBus, foa);
}).add;

//another granular, newDirections
SynthDef(\foaDust12, {arg outBus, dur = 0.05, amp = 0.125, density = 10.0;
    var src, foa, encoder;
    var loFreq = 100.0, hiFreq = 5000, klankArgs, streams = 12;

    klankArgs = Ref([[800, 1071, 1153, 1723], nil, dur/20 * [1, 1, 1, 1]]);

    src = Dust.ar(density * Array.fill(streams, {1}) / streams, amp);
    src = Klank.ar(klankArgs, src);

    src = LPF.ar(src,
      EnvGen.kr(Env([loFreq, hiFreq, loFreq], [0.1, 0.9], \exp), timeScale: dur),
      EnvGen.kr(Env([0, 1, 0], [0.1, 0.9], \sin), timeScale: dur)
    );

    encoder = FoaEncoderMatrix.newDirections(Array.fill(streams, {[pi.rand2, pi.rand2]}), nil);
    foa = FoaEncode.ar(src, encoder);
    Out.ar(outBus, foa);
}).add;

//focus and proximity together
SynthDef(\foaDecorFP, {
    arg outBus, dur = 0.05, amp = 0.25, angle = 0, theta = 0, phi = 0, distance = 1.0;
    var src, foa, env;
    var freq = 20.0;
    env = EnvGen.kr(Env([0, 1, 0], [0.5, 0.5], \sin), timeScale: dur, doneAction: 2);
    src = PinkNoise.ar(amp * [1, 1, 1, 1]);
    foa = FoaEncode.ar(src, FoaEncoderMatrix.newAtoB);
    foa = FoaTransform.ar(foa, 'focus', angle, theta, phi);
    foa = HPF.ar(foa, freq);
    foa = FoaTransform.ar(foa, 'proximity', distance);
    Out.ar(outBus, foa * env);
}).add;

//rotation, try with soundscape recordings
~sndBuf = Buffer.read(s, Atk.userSoundsDir ++ "/b-format/Leonard-Orfeo_Trio.wav");

SynthDef(\bFormatRot, {
  arg outBus, buffer, dur = 1.0, amp = 0.25, rotRate = 1.0;
  var src, env, foa;
  var rotAngle, tilAngle, tumAngle;

  env = EnvGen.kr(Env([0, 1, 1, 0], [0.1, dur - 0.2, 0.1], \sin));

  rotAngle = LFNoise2.kr(rotRate, 2pi);
  tilAngle = LFNoise2.kr(rotRate, 2pi);
  tumAngle = LFNoise2.kr(rotRate, 2pi);

  src = PlayBuf.ar(~sndBuf.numChannels, ~sndBuf, BufRateScale.kr(~sndBuf));

  //already in B-format
  foa = src;

  //transform
  foa = FoaTransform.ar(foa, 'rtt', rotAngle, tilAngle, tumAngle);

  Out.ar(outBus, env * foa)
}).add;

//effects in ambisonics
SynthDef(\foaFLFla, {
  arg outBus, dur = 0.05, amp = 0.25, freq = 0.5, del = 0.001;
  var src, foa;

  src = PinkNoise.ar(amp) * EnvGen.kr(Env([0, 1, 0], [0.5, 0.5], \sin), timeScale: dur);

  //encode
  foa = FoaEncode.ar(src, FoaEncoderMatrix.newDirection(45.degrad));

  //flange
  foa = 0.5 * (foa + DelayC.ar(foa, del, SinOsc.kr(freq, -pi/2).range(0, del)));

  Out.ar(outBus, foa)
}).add;

SynthDef(\foaFLFlaQ, {
  arg outBus, dur = 0.05, amp = 0.25, freq = 0.5, del = 0.001;
  var src, foa;

  src = PinkNoise.ar(amp) * EnvGen.kr(Env([0, 1, 0], [0.5, 0.5], \sin), timeScale: dur);

  //encode
  foa = FoaEncode.ar(src, FoaEncoderMatrix.newDirection(45.degrad));

  //flange
  foa = 0.5 * (foa + DelayC.ar(foa, del, SinOsc.kr(freq, [-pi/2, 0, pi/2, pi]).range(0, del)));

  Out.ar(outBus, foa)
}).add;



//decoding
SynthDef(\foaDecode, {arg inBus;
	var foa, decoderMatrix, out;
	foa = In.ar(inBus, 8);
	decoderMatrix = FoaDecoderMatrix.newDiametric([-22.5, 22.5, -67.5, 67.5].degrad, k: 'energy');
	out = FoaDecode.ar(foa, decoderMatrix);
 	Out.ar(0, out);
}).add;

//UHJ for stereo

)

// start the decoder, reading bus 'foaBus' at the \tail
~foaDecode = Synth(\foaDecode, [\inBus, ~foaBus], 1, \addToTail);

//set encoder
Synth(\foaSpread, [\outBus, ~foaBus, \dur, rrand(1, 5), \angle, pi/2, \theta, -30.degrad]);
Synth(\foaDiffuse, [\outBus, ~foaBus, \dur, rrand(1, 5)]);

//dust
Synth(\foaDust, [\outBus, ~foaBus, \dur, rrand(1, 5), \density, 20, \amp, 0.5])
Synth(\foaDust12, [\outBus, ~foaBus, \dur, rrand(1, 5), \density, 20, \amp, 0.7])

//focus and proximity
Synth(\foaDecorFP, [\outBus, ~foaBus, \dur, 1.0, \amp, -15.dbamp, \angle, 90.degrad, \distance, 1.0])
Synth(\foaDecorFP, [\outBus, ~foaBus, \dur, 1.0, \amp, -13.dbamp, \angle, 60.degrad, \distance, 0.25])
Synth(\foaDecorFP, [\outBus, ~foaBus, \dur, 1.0, \amp, -11.dbamp, \angle, 30.degrad, \distance, 0.125])
Synth(\foaDecorFP, [\outBus, ~foaBus, \dur, 1.0, \amp, -9.dbamp, \angle, 0.degrad, \distance, 0.0625])

//rotate
Synth(\bFormatRot, [\outBus, ~foaBus, \buffer, ~sndBuf, \dur, 5.5, \amp, -12.dbamp, \rotRate, 0.5])
Synth(\bFormatRot, [\outBus, ~foaBus, \buffer, ~sndBuf, \dur, 5.5, \amp, -12.dbamp, \rotRate, 1.0])
Synth(\bFormatRot, [\outBus, ~foaBus, \buffer, ~sndBuf, \dur, 5.5, \amp, -12.dbamp, \rotRate, 4.0])

//flange
Synth(\foaFLFla, [\outBus, ~foaBus, \dur, 5.0])
Synth(\foaFLFla, [\outBus, ~foaBus, \dur, 5.0, \freq, 1.0/10.0])

Synth(\foaFLFlaQ, [\outBus, ~foaBus, \dur, 5.0])
Synth(\foaFLFlaQ, [\outBus, ~foaBus, \dur, 5.0, \freq, 1.0/10.0])
(
Tdef(\randPan, {
	inf.do({
    Synth(\foaDecor, [\outBus, ~foaBus, \angle, (pi/2).rand])
    Synth(\foaDetunPch, [\outBus, ~foaBus, \dur, 1.0, \freq, rrand(220, 440), \amp, -24.dbamp]);
		0.1.wait;
	})
}).play;
)

Routine.run({
  inf.do({
    Synth(\foaPanB, [\outBus, ~foaBus, \duration, 1, \theta, pi.rand2, \phi, pi.rand2,
                     \distance, 1.0.exprand(0.0625)]);
  1.wait;
  })
})


~foaDecode.free; // free the decoder
a.free; // free the audio bus
"klanks.scd".loadRelative;
