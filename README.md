# encoding-testing

A set of scripts for bulk encoding media with HandBrake, then computing VMAF, PSNR, and SSIM scores for comparison.  Mostly made for homelabbing shenanigans.

## Verbose Explanation

I got tired of seeing people slackjaw about how they only keep remuxes of their blurays or DVDs because they've already been compressed to be put on the bluray, and thus compressing a second time is sacrilege and shouldn't be done.

To a point, they're right.  If you try to compress a 25GB movie to 1GB, then try to compress it again, you're going to end up with a bad experience (and I have the VMAF/PSNR/SSIM scores to back that up!).  But, what is that point?  Because that logic is flawed a little bit, at least for me who's seen some 200MBps samples that get compressed to fit a bluray.

So I queued up a bunch of encodes, wrote a bunch of scripts to do math, then sat on the couch and watched my movies.  I then made a bunch of posts on reddit, and elsewhere, for people to ignore.

So here are those scripts so you can do this too.  Hopefully.

## Requirements

* HandBrake, [either installed locally](https://handbrake.fr/) (specifically the command line version) or using [jlesage's docker image](https://github.com/jlesage/docker-handbrake).  I had neither the attention span nor the arcane knowledge to set up all these encodes with ffmpeg directly, so, I used HandBrake as a good middleground.
* ffmpeg/ffprobe.  Used to calculate VMAF scores and do a few checks.  Yeah, still had to learn the arcane knowledge.  Install instructions below.
* [ffmpeg-quality-metrics](https://github.com/slhck/ffmpeg-quality-metrics).  Used to calculate PSNR and SSIM scores.  I know it can calculate VMAF scores too, I just never got around to setting it up.
* [Python](https://www.python.org/downloads/), 3.9 or above preferably.  Any version of 3.x *should* work, but I *should* spend my time doing more productive things, and yet, here I am.
* A _lot_ of time.

Theoretically, this should work on Windows as well as Linux or Mac.  I successfully ran all the encodes in Windows (through cygwin, I bet WSL would work) and on Linux thanks to jlesage's image, and computed scores on Windows and Linux.  I'm sorry to Mac users, I cannot provide install instructions at this time because I don't have any iOS devices to test on.  Feel free to contribute them if you get it working locally!

### Installing ffmpeg & ffprobe

#### Linux
(If you needed these instructions)
```
wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz
tar xvf ffmpeg-git-amd64-static.tar.xz
sudo mv ffmpeg-git-amd64-static/ff* /usr/local/bin/
```

#### Windows
1. Download the git essentials build from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/).  Should be the first one under "git master builds"
2. Unpack file
3. Copy the bin/doc/presets folders and LICENSE/README.txt files to an appropriate place (e.g. `C:\Program Files\ffmpeg`).
4. Add the bin folder to your path (e.g. `C:\Program Files\ffmpeg\bin\​`)

## Execution

1. Create reference file.  This should be a 3-10 minute clip of content you want to compare various encoders with.  I suggest around 5-7 minutes if possible, cut from the highest quality version of the content you want to compare encoders with.  Name this `<index>0000. <source name> reference.mkv`, so the scripts know to encode using it as a base and compute scores with it.
2. Run the various `template_*.sh` scripts with appropriate arguments, more information at `encode-scripts/README.md`.  Encodes will be present at `<index>. <source name>/`.
3. Wait for encodes to complete.
4. Move encodes to the folder `data/` next to `generate_metrics.sh`.  That script expects encodes at that location.
5. Run `generate_metrics.sh <index> <source name>` to compute VMAF, PSNR, and SSIM scores between the various encodes and the reference file.  These reports will be printed to file at `reports/`, next to this file.
6. Run `read_quality_metrics.py`.  It will read all the scores and format them to TSV for easy pasting, and also write them to TSV files in `reports/summaries/`.  It will also calculate the bit rate of each encode and write those values out to `reports/summaries/` as well.
7. Copy these values to your spreadsheet of choice, highlight them with pretty colors, and interpret as you please!
