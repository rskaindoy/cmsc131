"""Reference values for the Block 6 compound interest program.

The shipped interest.input runs one case. This prints the year-by-year figures
for whatever case you give it, computed the way your assembly has to compute
them: centavos as whole numbers, and every division truncating.

    python b6_validation.py                 # 100000 centavos, 5%, 3 years
    python b6_validation.py 250000 7 5      # your own case

The rightmost column is the half-centavo the truncation threw away. Add those
up and you have the difference between your program and one that rounds.
"""

import sys


def main() -> None:
    args = sys.argv[1:]
    balance = int(args[0]) if len(args) > 0 else 100000
    rate = int(args[1]) if len(args) > 1 else 5
    years = int(args[2]) if len(args) > 2 else 3

    start = balance

    print(f"Starting balance: {balance} centavos ({balance // 100}.{balance % 100:02d})")
    print(f"Rate: {rate}%   Term: {years} years")
    print()
    print("Year | Balance before | Interest | Balance after | Prints as | Discarded")
    print("-" * 76)

    discarded_total = 0
    for year in range(1, years + 1):
        before = balance
        product = before * rate
        interest = product // 100
        discarded = product % 100
        discarded_total += discarded
        balance = before + interest
        shown = f"{balance // 100}.{balance % 100:02d}"
        print(
            f"{year:4} | {before:14} | {interest:8} | {balance:13} | {shown:>9} | {discarded:9}"
        )

    total_interest = balance - start
    print()
    print(f"Total interest earned: {total_interest // 100}.{total_interest % 100:02d}")
    print(f"Hundredths of a centavo discarded along the way: {discarded_total}")


if __name__ == "__main__":
    main()
