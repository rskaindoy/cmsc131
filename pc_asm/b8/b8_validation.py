"""Run the exit check program against seven cases.

`make PROG=surname_exitcheck check` compares one run against the sample in
the manual. That run proves the prompts and one path through the program.
It does not prove a count of one, a value of 4095, or an average that
truncates. This script covers seven cases.

Build the program first. This script runs the program, and it does not build
it:

    make PROG=surname_exitcheck

Then run the script with the same stem:

    python b8_validation.py surname_exitcheck

On Linux the command is `python3 b8_validation.py surname_exitcheck`. With no
argument the script looks for `exitcheck`. The script runs the `.exe` on
Windows and the bare name on Linux, and it prints the path it chose.

The script reads the six report lines only, from `Packed:` to the unpacked
first reading. It ignores everything before the `Packed:` line. The manual
does not fix the wording of a prompt or of a rejection, so the script does
not judge that wording. It checks input consumption instead: every case
types out-of-range numbers or a fixed number of readings, and a program
that consumes them in the wrong order prints a wrong report or waits for
input that never comes.

Each case runs the program once, in its own process, with its own input.
The program must exit with status 0 and must write nothing to stderr. A
message on stderr is a diagnostic, and a passing run has none.

The script judges a repeated maximum on any sensor that holds it. The
average is a truncated average, and a value equal to the average is not
above it. When every reading holds the same value, the report must show
zero readings above the average.
"""

import os
import subprocess
import sys
from typing import Dict, List, Optional, Tuple

TIMEOUT_SECONDS = 10

# The line that names a sensor. A tie is allowed on this line.
LARGEST_PREFIX = "Largest from sensor: "

# Seven cases. Each case is a name, a list of (sensor, value) pairs, and an
# optional dictionary of out-of-range numbers to type before the good ones.
# The last case is the all-equal case.
#
# The count rejects are -1, 0, and 21. 21 sits next to the upper bound, so a
# program that accepts 21 reads 21 readings, consumes the rest of the input
# as readings, and fails. A reject of 25 would let a program with an upper
# bound of 24 pass.
Case = Tuple[str, List[Tuple[int, int]], Optional[Dict[str, List[int]]]]

CASES = [
    ("one reading", [(5, 42)], None),
    ("both fields at their limits", [(15, 4095), (0, 0)], None),
    ("an average that truncates", [(1, 1), (2, 2), (3, 4)], None),
    ("the largest reading entered first", [(9, 500), (1, 10), (2, 20)], None),
    ("twenty readings", [(i % 16, i * 3 + 1) for i in range(20)], None),
    (
        "out-of-range input before every good number",
        [(2, 100), (7, 300)],
        {"count": [-1, 0, 21], "sensor": [16, -1], "value": [4096, -5]},
    ),
    ("every reading holding the same value", [(3, 100), (4, 100), (5, 100)], None),
]


def largest_candidates(readings: List[Tuple[int, int]]) -> List[int]:
    """Every sensor that holds the largest value."""
    best = max(value for _, value in readings)
    return [sensor for sensor, value in readings if value == best]


def report_for(readings: List[Tuple[int, int]]) -> List[str]:
    """The six lines a correct program prints, computed from the spec."""
    packed = [(sensor << 12) | value for sensor, value in readings]
    total = sum(value for _, value in readings)
    average = total // len(readings)
    largest = max(readings, key=lambda reading: reading[1])
    above = sum(1 for _, value in readings if value > average)

    return [
        "Packed: " + " ".join(str(p) for p in packed),
        "Sum: %d" % total,
        "Average: %d" % average,
        LARGEST_PREFIX + str(largest[0]),
        "Above average: %d" % above,
        "First reading unpacked: sensor %d, value %d" % (readings[0][0], readings[0][1]),
    ]


def stdin_for(readings: List[Tuple[int, int]], rejects: Optional[Dict[str, List[int]]] = None) -> str:
    """The keystrokes a run needs, one number per line.

    `rejects` holds out-of-range numbers to type before the good ones. A
    program that validates ignores them and asks again. A program that does
    not read them as real fails the comparison.
    """
    rejects = rejects or {}
    lines = [str(n) for n in rejects.get("count", [])]
    lines.append(str(len(readings)))
    for sensor, value in readings:
        lines += [str(n) for n in rejects.get("sensor", [])]
        lines.append(str(sensor))
        lines += [str(n) for n in rejects.get("value", [])]
        lines.append(str(value))
    return "\n".join(lines) + "\n"


def report_lines(output: str) -> List[str]:
    """The report, which starts at the `Packed:` line.

    Blank lines after the report are dropped, so a trailing newline does not
    count against the program. Any other line after the report stays in the
    list and fails the comparison.
    """
    lines = [line.rstrip() for line in output.replace("\r\n", "\n").split("\n")]
    start = None
    for index, line in enumerate(lines):
        if line.startswith("Packed:"):
            start = index
            break
    if start is None:
        return []

    report = lines[start:]
    while report and report[-1] == "":
        report.pop()
    return report


def compare(actual: List[str], readings: List[Tuple[int, int]]) -> List[str]:
    """Compare one report against the spec. Returns a list of problems.

    The largest-value line accepts any sensor that holds the largest value.
    Every other line must match exactly. No nonblank line may follow the
    report.
    """
    expected = report_for(readings)
    candidates = set(LARGEST_PREFIX + str(sensor) for sensor in largest_candidates(readings))
    problems = []

    if len(actual) < len(expected):
        problems.append("the report has %d line(s), and six are required." % len(actual))

    for index, want in enumerate(expected):
        if index >= len(actual):
            problems.append("missing line %d: %s" % (index + 1, want))
            continue
        got = actual[index]
        if want.startswith(LARGEST_PREFIX):
            if got not in candidates:
                problems.append("want one of: %s" % ", ".join(sorted(candidates)))
                problems.append("got:         %s" % got)
        elif got != want:
            problems.append("want: %s" % want)
            problems.append("got:  %s" % got)

    for line in actual[len(expected) :]:
        if line.strip():
            problems.append("extra line after the report: %s" % line)

    return problems


def executable_names(stem: str, windows: Optional[bool] = None) -> List[str]:
    """The file names to try for a program stem, in order of preference.

    Windows links `stem.exe`, so it comes first there. Linux links `stem`,
    so it comes first there. The other name is tried second, for a folder
    copied between machines.
    """
    if windows is None:
        windows = os.name == "nt"
    if windows:
        return [stem + ".exe", stem]
    return [stem, stem + ".exe"]


def find_program(stem: str = "exitcheck", directory: str = ".", windows: Optional[bool] = None) -> Optional[str]:
    """The path of the built program for `stem`, or None."""
    for name in executable_names(stem, windows):
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            return path
    return None


def resolve_program(given: Optional[str], directory: str = ".", windows: Optional[bool] = None) -> Optional[str]:
    """Turn the command-line argument into a program path.

    No argument means the stem `exitcheck`. A path to a file is used as
    given. Any other word is a stem, such as `cruz_exitcheck`, resolved the
    way `exitcheck` is.
    """
    if given is None:
        return find_program("exitcheck", directory, windows)
    if os.path.isfile(given):
        return given
    return find_program(given, directory, windows)


def run(command: List[str], keystrokes: str) -> Tuple[Optional[str], int, str, str]:
    """Run the program once. Returns stdout, status, stderr, and a reason.

    The reason is empty when the program ran to completion. It names the
    problem when the program did not start or did not finish.
    """
    try:
        finished = subprocess.run(
            command,
            input=keystrokes,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return None, 0, "", (
            "it was still running after %d seconds. A rejection loop that "
            "never accepts a number does this, and so does a count above 20 "
            "that the program accepted." % TIMEOUT_SECONDS
        )
    except OSError as problem:
        return None, 0, "", "it would not start (%s)" % problem

    return finished.stdout, finished.returncode, finished.stderr, ""


def judge(output: str, status: int, readings: List[Tuple[int, int]], stderr: str = "") -> Tuple[bool, List[str]]:
    """Judge one captured run. Returns a verdict and the lines to print."""
    if status != 0:
        return False, [
            "the program exited with status %d" % status,
            "On Windows, 0xC0000095 is a div whose quotient overflowed eax.",
        ]

    if stderr.strip():
        detail = ["the program wrote to stderr, and a passing run writes nothing there:"]
        for line in stderr.replace("\r\n", "\n").split("\n")[:6]:
            if line.strip():
                detail.append("  " + line.rstrip())
        return False, detail

    actual = report_lines(output)
    if not actual:
        detail = ["no line in the output starts with 'Packed:'."]
        detail.append("The first lines of the output were:")
        for line in output.replace("\r\n", "\n").split("\n")[:8]:
            detail.append("  " + line.rstrip())
        return False, detail

    problems = compare(actual, readings)
    if problems:
        return False, problems

    return True, []


def check(command: List[str], name: str, readings: List[Tuple[int, int]], rejects: Optional[Dict[str, List[int]]] = None) -> bool:
    output, status, stderr, reason = run(command, stdin_for(readings, rejects))

    if output is None:
        print("  FAIL  %s" % name)
        print("        %s" % reason)
        return False

    ok, detail = judge(output, status, readings, stderr)
    if ok:
        print("  ok    %s" % name)
        return True

    print("  FAIL  %s" % name)
    print("        readings: %s" % (readings,))
    for line in detail:
        print("        %s" % line)
    return False


def main(argv: Optional[List[str]] = None) -> int:
    argv = sys.argv if argv is None else argv
    given = argv[1] if len(argv) > 1 else None
    program = resolve_program(given)
    if program is None:
        stem = "exitcheck" if given is None else os.path.basename(given)
        if stem.endswith(".exe"):
            stem = stem[:-4]
        print()
        print("No %s program here. Build one first:" % stem)
        print()
        print("    make PROG=%s" % stem)
        print()
        return 1

    # A bare file name needs the ./ prefix, or the shell searches PATH.
    if os.path.dirname(program) == "":
        program = os.path.join(".", program)

    print()
    print("Running %s against seven cases." % program)
    print()

    passed = 0
    failed = 0
    for name, readings, rejects in CASES:
        if check([program], name, readings, rejects):
            passed += 1
        else:
            failed += 1

    print()
    if failed == 0:
        print("All seven cases matched.")
    else:
        print("%d matched, %d did not. Start with the first FAIL above." % (passed, failed))
    print()

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
