"""Reference values for the Block 2 temperature converter.

The shipped convert.input holds one temperature, so `make PROG=convert check`
proves one case. This prints the rest, computed the same way your assembly has
to compute them: whole numbers throughout, every division truncating.

    python b2_validation.py

The right-hand column is the one worth staring at. Feed the program 100 and
you get 100 back. Feed it 69 and you get 68. Nothing is broken when that
happens, and the table shows you how often it happens.
"""

ROWS: int = 100


def celsius_to_fahrenheit(celsius: int) -> int:
    return (celsius * 9) // 5 + 32


def fahrenheit_to_kelvin(fahrenheit: int) -> int:
    return ((fahrenheit - 32) * 5) // 9 + 273


def kelvin_to_celsius(kelvin: int) -> int:
    return kelvin - 273


def main() -> None:
    print("Celsius | Fahrenheit | Kelvin | Back to Celsius | Lost")
    print("-" * 58)

    lost = 0
    for celsius in range(0, ROWS + 1):
        fahrenheit = celsius_to_fahrenheit(celsius)
        kelvin = fahrenheit_to_kelvin(fahrenheit)
        final = kelvin_to_celsius(kelvin)
        drift = celsius - final
        if drift:
            lost += 1
        print(f"{celsius:7} | {fahrenheit:10} | {kelvin:6} | {final:15} | {drift:4}")

    print()
    print(f"{lost} of {ROWS + 1} round trips did not come back to where they started.")
    print("Every one of those is a remainder that a div threw away.")


if __name__ == "__main__":
    main()
