## Encoding Scripts and Presets

These are the scripts I run to generate encodes for VMAF/PSNR/SSIM calculation/comparison.  They all are run as `<script> <index> <source name>`, e.g. `template.sh 1 bluray`.  It'll create the logs folder from ffmpeg then run HandBrake as necessary.

I'm actually a tiny bit proud of figuring out how to not encode a file if it's currently being encoded by another computer.

The file `presets_with_denoise.json` is all the HandBrake presets I created to get this up and running.  You should be able to import it into any HandBrake instance and create encodes equal to mine (if you have the same sources ;) ).  They should all be RF/ICQ 20, all default, with the only differences being encoder used (H264/H265 with/out hardware acceleration, all QSV set to quality), with Animation tune for two CPU profiles and additional presets with the denoise filter turned on.

## TODO

* Fix output saving.  I combine stdout and stderr, and the output file from HandBrake ends up having `Encoding task 1 of 1 ...` lines intertwined with output like `[15:03:47] work: ...`.
* Fix how the FPS is acquired, there's a line containing `average encoding speed for job is X fps` which I should grep for, instead of the last `Encoding task 1 of 1` that you can see commented out in the encode function.  It's easier to understand and should be simpler overall.

## Why did I duplicate so much code into seven extra scripts?

Two reasons:

First, the base `template.sh` is the mother script.  It's the real deal, runs all the encodes, fancy stuff.  The problem is that it also includes encode commands that use hardware encoders.  That's actually great, except I have nothing in my lab that has an Intel iGPU and Nvidia GPU, so I split into `_cpu.sh`, `_nvenc.sh`, and `_qsv.sh` versions.  Running those will only run the relevant encodes, so they can be run on machines that only have one kind of hardware encoder (or software only).


Second, the `_degrain` variants run encoder presets with a denoise filter turned on, which makes it not exactly the same as the base template.  In fact, there's about 3x as many denoise encode combinations than non-denoise.  That's because it's adding another parameter which quadruples the encode count for this source (double for the first encode, double for the second encode).  But since I encoded the grainy source with the normal set of encoder presets previously, I discard those here, which works out to a quarter of the final output not encoded, thus 3x.  I don't know why I explained the rough math behind there being 3x encodes.

Anyways, degraining/denoising adds more variables, which by the laws of combinatorics means we get more outputs.

I'm pretty sure there's no functional difference between these scripts besides the exact encodes they run.  And yes, I could have 'combined' them with option flags in the template script, but I really didn't feel like it when the idea came to me at 2am, and I wanted to go to bed already.

And yes again, I know there should be a third set of four scripts for the Animation tune for 2d/2dg.  I had already encoded those by the time I thought of this, but it's worth doing in the future anyways.
