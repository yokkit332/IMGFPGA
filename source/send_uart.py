import argparse
from pathlib import Path

import serial

CMD_MODE = 0xA0
CMD_THRESHOLD = 0xA1
CMD_FRAME_START = 0xA2


def read_mem_file(path: Path, expected_pixels: int) -> bytes:
    payload = bytearray()
    pixel_count = 0

    for line_number, original_line in enumerate(path.read_text().splitlines(), start=1):
        line = original_line.split("//", 1)[0].strip()

        if not line:
            continue

        if line.lower().startswith("0x"):
            line = line[2:]

        if len(line) != 6:
            raise ValueError(
                f"Line {line_number}: expected RRGGBB, received {original_line!r}"
            )

        try:
            pixel = int(line, 16)
        except ValueError as error:
            raise ValueError(
                f"Line {line_number}: invalid hexadecimal value {original_line!r}"
            ) from error

        payload.extend(
            (
                (pixel >> 16) & 0xFF,
                (pixel >> 8) & 0xFF,
                pixel & 0xFF,
            )
        )
        pixel_count += 1

    if pixel_count != expected_pixels:
        raise ValueError(
            f"Expected {expected_pixels} pixels, found {pixel_count}"
        )

    return bytes(payload)


def send_uart_input(
    port: str,
    baud_rate: int,
    mem_file: Path,
    mode: int,
    threshold: int,
    width: int,
    height: int,
) -> None:
    if not 0 <= mode <= 7:
        raise ValueError("Mode must be between 0 and 7")

    if not 0 <= threshold <= 31:
        raise ValueError("Threshold must be between 0 and 31")

    expected_pixels = width * height
    image_payload = read_mem_file(mem_file, expected_pixels)
    header = bytes(
        (
            CMD_MODE,
            mode,
            CMD_THRESHOLD,
            threshold,
            CMD_FRAME_START,
        )
    )

    with serial.Serial(
        port=port,
        baudrate=baud_rate,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=1,
        write_timeout=10,
    ) as uart:
        uart.reset_input_buffer()
        uart.reset_output_buffer()
        uart.write(header)
        uart.write(image_payload)
        uart.flush()

    print(f"Sent mode: {mode}")
    print(f"Sent threshold: {threshold}")
    print(f"Sent pixels: {expected_pixels}")
    print(f"Sent RGB bytes: {len(image_payload)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--mem", required=True, type=Path)
    parser.add_argument("--mode", required=True, type=int)
    parser.add_argument("--threshold", required=True, type=int)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--width", type=int, default=80)
    parser.add_argument("--height", type=int, default=60)
    args = parser.parse_args()

    send_uart_input(
        port=args.port,
        baud_rate=args.baud,
        mem_file=args.mem,
        mode=args.mode,
        threshold=args.threshold,
        width=args.width,
        height=args.height,
    )


if __name__ == "__main__":
    main()