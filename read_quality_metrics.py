import json
import pathlib
import subprocess
import typing

import xml.etree.ElementTree as ET

from utils import log


def _run_command(command: str) -> (int, typing.List[str], typing.List[str]):
    """
    Run a given command.  I have no idea if this works in Linux, but probably does.

    :param command: command to run
    :return: return code, stdout, and stderr
    """

    process = subprocess.Popen(
        command,
        universal_newlines=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        encoding="utf-8", errors="backslashreplace"
    )

    stdout = []
    while True:
        process_stdout = process.stdout.readline()
        if process_stdout == "" and process.poll() is not None:
            break

        stdout.append(process_stdout.strip())

    return_code = process.poll()
    stderr = process.stderr.readlines()

    return return_code, [x.strip() for x in stdout if x], [x.strip() for x in stderr if x]


def _get_lows(scores: list) -> (float, float):
    one_percent_scores = scores[:int(round(len(scores) / 100, 0))]
    point_one_percent_scores = scores[:int(round(len(scores) / 1000, 0))]
    one_percent_low = sum(one_percent_scores) / float(len(one_percent_scores))
    point_one_percent_low = sum(point_one_percent_scores) / float(len(point_one_percent_scores))
    return one_percent_low, point_one_percent_low


def get_bitrate(file_path: pathlib.Path) -> int:
    mkvpropedit_command = "mkvpropedit --add-track-statistics-tags \"{}\"".format(file_path)
    code, out, err = _run_command(mkvpropedit_command)
    if code != 0:
        if out:
            log.debug(out)
        if err:
            log.error(err)
        raise RuntimeError("Got code [{}] from [{}]".format(code, mkvpropedit_command))

    ffprobe_template = "ffprobe -v error -select_streams v:0 -show_entries stream_tags=BPS -of csv=p=0 \"{}\""
    ffprobe_command = ffprobe_template.format(file_path)
    code, out, err = _run_command(ffprobe_command)
    if code != 0:
        if out:
            log.debug(out)
        if err:
            log.error(err)
        raise RuntimeError("Got code [{}] from [{}]".format(code, ffprobe_command))

    return int(out[0])


def read_vmaf_scores(compressed_file_report: pathlib.Path) -> list:
    if compressed_file_report.exists():
        root = ET.fromstring(compressed_file_report.read_text())

        frame_scores = sorted([float(x.attrib["vmaf"]) for x in root[2]])
        one_percent_low, point_one_percent_low = _get_lows(frame_scores)

        vmaf_metrics = [x for x in root[3] if x.attrib["name"] == "vmaf"][0]

        # <metric name="vmaf" min="88.246675" max="100.000000" mean="94.799103" harmonic_mean="94.747470" />
        vmaf_minimum = round(float(vmaf_metrics.attrib["min"]), 6)
        vmaf_mean = round(float(vmaf_metrics.attrib["mean"]), 6)
        vmaf_harmonic = round(float(vmaf_metrics.attrib["harmonic_mean"]), 6)

        # Unused, but might as well leave it.
        # vmaf_maximum = round(float(vmaf_metrics.attrib["max"]), 6)

        return [vmaf_minimum, vmaf_mean, vmaf_harmonic, one_percent_low, point_one_percent_low]
    return [0, 0, 0, 0, 0]


def get_psnr_and_ssim_scores(report_file: pathlib.Path) -> list:
    if report_file.exists():
        quality_report = json.loads(report_file.read_text())
    else:
        quality_report = {}

    psnr_median = str(quality_report.get("global", {}).get("psnr", {}).get("median", "0.0"))
    psnr_min = str(quality_report.get("global", {}).get("psnr", {}).get("min", "0.0"))
    ssim_median = str(quality_report.get("global", {}).get("ssim", {}).get("median", "0.0"))
    ssim_min = str(quality_report.get("global", {}).get("ssim", {}).get("min", "0.0"))

    psnr_scores = []
    for score in quality_report.get("psnr", []):
        # ffmpeg_quality_metrics can report "Infinity" for PSNR for some reason, I'm just ignoring those values.
        # Sue me.  (Please don't.)
        if score.get("psnr_avg", None) and score["psnr_avg"] < 1000000:
            psnr_scores.append(float(score["psnr_avg"]))
    psnr_one_percent_low, psnr_point_one_percent_low = _get_lows(sorted(psnr_scores))

    ssim_scores = sorted([float(x["ssim_avg"]) for x in quality_report.get("ssim", [])])
    ssim_one_percent_low, ssim_point_one_percent_low = _get_lows(ssim_scores)

    return [
        psnr_median, psnr_one_percent_low, psnr_point_one_percent_low, psnr_min,
        ssim_median, ssim_one_percent_low, ssim_point_one_percent_low, ssim_min
    ]


def output_scores(data_path: pathlib.Path, reports_path: pathlib.Path, indexed_source_name: str) -> None:
    source_name = indexed_source_name.split(". ")[1]
    source_index = indexed_source_name.split(". ")[0][0]

    log.info("Processing: [{}]".format(source_name))
    files = sorted([x for x in data_path.iterdir() if x.name.endswith(".mkv") and source_name in x.name])

    log.debug("[{}] VMAF Scores: ".format(source_name))
    vmaf_scores = []
    for file in files:
        if "reference" in file.name:
            continue
        file_scores = read_vmaf_scores(reports_path.joinpath(file.name.replace("mkv", "xml")))
        vmaf_scores.append(file_scores)
    print("\n".join(["\t".join([str(y) for y in x]) for x in vmaf_scores]))

    log.debug("[{}] PSNR & SSIM Scores: ".format(source_name))
    psnr_and_ssim_scores = []
    for file in files:
        if "reference" in file.name:
            continue
        file_scores = get_psnr_and_ssim_scores(reports_path.joinpath(file.name.replace("mkv", "json")))
        psnr_and_ssim_scores.append(file_scores)
    print("\n".join(["\t".join([str(y) for y in x]) for x in psnr_and_ssim_scores]))

    log.debug("[{}] Calculating bit rates".format(source_name))
    bit_rates = []
    for file in files:
        if "reference" in file.name:
            get_bitrate(file)
            continue
        bit_rates.append(get_bitrate(file))
    print("\n".join([str(x) for x in bit_rates]))

    log.debug("Logging scores and bit rates to files")
    summary_folder = reports_path.joinpath("summaries")
    summary_folder.mkdir(exist_ok=True)

    vmaf_summary_file = summary_folder.joinpath("{}. {} vmaf.tsv".format(source_index, source_name))
    vmaf_summary_file.write_text("\n".join(["\t".join([str(y) for y in x]) for x in vmaf_scores]))

    psnr_and_ssim_summary_file = summary_folder.joinpath("{}. {} psnr_and_ssim.tsv".format(source_index, source_name))
    psnr_and_ssim_summary_file.write_text("\n".join(["\t".join([str(y) for y in x]) for x in psnr_and_ssim_scores]))

    bit_rate_file = summary_folder.joinpath("{}. {} bit_rate.txt".format(source_index, source_name))
    bit_rate_file.write_text("\n".join([str(x) for x in bit_rates]))


if __name__ == "__main__":
    data_folder = pathlib.Path("data")
    reports_folder = pathlib.Path("reports")
    filenames = sorted([x for x in data_folder.iterdir() if x.name.endswith(".mkv") and "reference" in x.name])
    sources = [" ".join(x.name.split(" ")[:2]) for x in filenames]
    for source in sources:
        output_scores(data_folder, reports_folder, source)
