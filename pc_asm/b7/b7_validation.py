"""Run the Block 7 packing program against seven cases.

`make PROG=pack check` compares one run against `pack.expected`. That run
proves the prompts and one path through the program. It does not prove the
maximum value, the zero value, or an input wider than its field. This script
covers those cases.

Build the program first. This script runs the program, and it does not build
it:

    make PROG=pack

Then run the script:

    python b7_validation.py

On Linux the command is `python3 b7_validation.py`.

The script runs `pack.exe` on Windows and `pack` on Linux. When the program
has another name, give the name or the path as the one argument:

    python b7_validation.py mypack

The script reads the four report lines only: `Packed:`, `Unpacked version:`,
`Unpacked flag:`, and `Unpacked length:`. It ignores everything before the
`Packed:` line. The fixture still checks the prompts.

Each case masks the input the way the manual requires. A version of 20
becomes 4, a flag of 2 becomes 0, and a length of 325 becomes 69. A program
that does not mask fails the last case.

Each case runs the program once, in its own process, with its own input. The
program must exit with status 0 and must write nothing to stderr. A message
on stderr is a diagnostic, and a passing run has none.

What this script cannot see: whether the packed value went through memory.
A program that keeps the value in a register and never stores to `packed`
prints the same four lines. The script reads output. It does not read code.
The defense checks the round trip.
"""

import os
import subprocess
import sys
from typing import List, Optional, Tuple

TIMEOUT_SECONDS = 10

# Each case is a name and the three numbers to type, in prompt order.
# The last case is deliberately wider than its fields.
CASES = [
    ("the sample from the manual", 4, 1, 69),
    ("all three fields at zero", 0, 0, 0),
    ("all three fields at their maximum", 15, 1, 255),
    ("the version on its own", 15, 0, 0),
    ("the flag on its own", 0, 1, 0),
    ("the length on its own", 0, 0, 255),
    ("two values wider than their fields", 20, 2, 325),
]


def mask_fields(version: int, flag: int, length: int) -> Tuple[int, int, int]:
    """Keep each value inside its field width."""
    return version & 0x0F, flag & 0x01, length & 0xFF


def report_for(version: int, flag: int, length: int) -> List[str]:
    """The four report lines a correct program prints for one case."""
    version, flag, length = mask_fields(version, flag, length)
    packed = (version << 12) | (flag << 8) | length
    return [
        "Packed: %d" % packed,
        "Unpacked version: %d" % version,
        "Unpacked flag: %d" % flag,
        "Unpacked length: %d" % length,
    ]


def keystrokes_for(version: int, flag: int, length: int) -> str:
    """The three numbers a run needs, one per line."""
    return "%d\n%d\n%d\n" % (version, flag, length)


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


def evaluate(output: str, status: int, expected: List[str], stderr: str = "") -> Tuple[bool, List[str]]:
    """Judge one captured run. Returns a verdict and the lines to print.

    The rules: the process must exit 0, stderr must be empty, the report
    must start, the four report lines must match, and no nonblank line may
    follow them.
    """
    if status != 0:
        return False, ["the program exited with status %d" % status]

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
        for line in output.replace("\r\n", "\n").split("\n")[:6]:
            detail.append("  " + line.rstrip())
        return False, detail

    if actual[: len(expected)] != expected:
        detail = []
        for index in range(max(len(expected), len(actual))):
            want = expected[index] if index < len(expected) else "(no line)"
            got = actual[index] if index < len(actual) else "(no line)"
            if want != got:
                detail.append("want: %s" % want)
                detail.append("got:  %s" % got)
        return False, detail

    extras = [line for line in actual[len(expected) :] if line != ""]
    if extras:
        detail = ["the report has %d extra line(s) after it:" % len(extras)]
        for line in extras:
            detail.append("  " + line)
        return False, detail

    return True, []


def executable_names(stem: str, windows: Optional[bool] = None) -> List[str]:
    """The file names to try for a program stem, in order of preference.

    Windows links `pack.exe`, so it comes first there. Linux links `pack`,
    so it comes first there. The other name is tried second, for a folder
    copied between machines.
    """
    if windows is None:
        windows = os.name == "nt"
    if windows:
        return [stem + ".exe", stem]
    return [stem, stem + ".exe"]


def find_program(stem: str = "pack", directory: str = ".", windows: Optional[bool] = None) -> Optional[str]:
    """The path of the built program for `stem`, or None."""
    for name in executable_names(stem, windows):
        path = os.path.join(directory, name)
        if os.path.isfile(path):
            return path
    return None


def resolve_program(given: Optional[str], directory: str = ".", windows: Optional[bool] = None) -> Optional[str]:
    """Turn the command-line argument into a program path.

    No argument means the stem `pack`. A path to a file is used as given. Any
    other word is a stem, resolved the way `pack` is.
    """
    if given is None:
        return find_program("pack", directory, windows)
    if os.path.isfile(given):
        return given
    return find_program(given, directory, windows)


def run(command: List[str], keys: str) -> Tuple[Optional[str], int, str, str]:
    """Run the program once. Returns stdout, status, stderr, and a reason.

    The reason is empty when the program ran to completion. It names the
    problem when the program did not start or did not finish.
    """
    try:
        finished = subprocess.run(
            command,
            input=keys,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return None, 0, "", (
            "it was still running after %d seconds. A program that waits for "
            "input it never receives does this." % TIMEOUT_SECONDS
        )
    except OSError as problem:
        return None, 0, "", "it would not start (%s)" % problem

    return finished.stdout, finished.returncode, finished.stderr, ""


def check(command: List[str], name: str, version: int, flag: int, length: int) -> bool:
    expected = report_for(version, flag, length)
    output, status, stderr, reason = run(command, keystrokes_for(version, flag, length))

    if output is None:
        print("  FAIL  %s" % name)
        print("        %s" % reason)
        return False

    ok, detail = evaluate(output, status, expected, stderr)
    if ok:
        print("  ok    %s" % name)
        return True

    print("  FAIL  %s" % name)
    print("        input: version %d, flag %d, length %d" % (version, flag, length))
    for line in detail:
        print("        %s" % line)
    return False


def main(argv: Optional[List[str]] = None) -> int:
    argv = sys.argv if argv is None else argv
    given = argv[1] if len(argv) > 1 else None
    program = resolve_program(given)
    if program is None:
        stem = "pack" if given is None else os.path.basename(given)
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
    for name, version, flag, length in CASES:
        if check([program], name, version, flag, length):
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
