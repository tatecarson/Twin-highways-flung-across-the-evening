/*
--5. a timelime that switches soundbanks at certain sections to create form


Things to add -

-- more control over what types of sounds get played
-- more though of envelopes on oneshot percussion sounds

*/

(
//setup

//for 8 channels
s.options.numOutputBusChannels_(8);
s.options.sampleRate_(48000);
s.options.outDevice_("UltraLite AVB");
s.newAllocators; //free previous busses
s.options.memSize=128*1024;
s.meter;
s.waitForBoot{
	//cleanup

	b.free; 	 //buffers
	a.remove;

	//loadfiles
	{
	"MasterLimiter.scd".loadRelative;
	"loadBuffers.scd".loadRelative;
	"SynthDefs.scd".loadRelative;

	s.sync;

	"ambisonicsSetup.scd".loadRelative;

	s.sync;

	"patterns.scd".loadRelative;

	s.sync;

	"monomeInit.scd".loadRelative;

	s.sync;

	"wekinator.scd".loadRelative;
	}.fork;
}
);
// s.makeGui
// OSCFunc.trace(false, true);

//to open wekinator from SC
//but is causing monome to act wierd so i took it out
/*"java -jar ~/wekimini/dist/WekiMini.jar ~/Documents/Supercollider/_OrgExamples/MyComps/Octophonia/WekinatorProject/WekinatorProject.wekproj".unixCmd;*/
// {SinOsc.ar}.play;
