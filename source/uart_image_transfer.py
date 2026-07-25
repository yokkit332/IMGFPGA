from __future__ import annotations

import argparse
import threading
import time
from pathlib import Path

import serial

CMD_MODE = 0xA0
CMD_THRESHOLD = 0xA1
CMD_FRAME_START = 0xA2


def read_mem_file(path: Path, expected_pixels: int) -> bytes:
    payload = bytearray()

    for line_number, original_line in enumerate(path.read_text().splitlines(), start=1):
        line = original_line.split("//", 1)[0].split("#", 1)[0].strip()

        if not line:
            continue

        if line.startswith("@"):
            continue

        token = line.split()[0]

        if len(token) != 6:
            raise ValueError(f"Line {line_number}: expected RRGGBB, received {token!r}")

        try:
            pixel = int(token, 16)
        except ValueError as error:
            raise ValueError(f"Line {line_number}: invalid hexadecimal pixel {token!r}") from error

        payload.extend(((pixel >> 16) & 0xFF, (pixel >> 8) & 0xFF, pixel & 0xFF))

    actual_pixels = len(payload) // 3

    if actual_pixels != expected_pixels:
        raise ValueError(f"Expected {expected_pixels} pixels, found {actual_pixels}")

    return bytes(payload)


def receive_exact(uart: serial.Serial, byte_count: int, timeout_seconds: float) -> bytes:
    received = bytearray()
    deadline = time.monotonic() + timeout_seconds

    while len(received) < byte_count:
        chunk = uart.read(min(4096, byte_count - len(received)))

        if chunk:
            received.extend(chunk)
            deadline = time.monotonic() + timeout_seconds
        elif time.monotonic() >= deadline:
            raise TimeoutError(f"Received {len(received)} of {byte_count} bytes before timeout")

    return bytes(received)


def write_mem_file(path: Path, data: bytes) -> None:
    if len(data) % 3 != 0:
        raise ValueError("Received byte count is not divisible by three")

    lines = []

    for index in range(0, len(data), 3):
        lines.append(f"{data[index]:02X}{data[index + 1]:02X}{data[index + 2]:02X}")

    path.write_text("\n".join(lines) + "\n")


def transfer_image(args: argparse.Namespace) -> None:
    if not 0 <= args.mode <= 4:
        raise ValueError("Mode must be between 0 and 4")

    if not 0 <= args.threshold <= 31:
        raise ValueError("Threshold must be between 0 and 31")

    payload = read_mem_file(args.input, args.pixels)
    expected_output_bytes = args.pixels * 3
    receive_result: dict[str, bytes] = {}
    receive_error: dict[str, BaseException] = {}

    with serial.Serial(
        port=args.port,
        baudrate=args.baud,
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=0.1,
        write_timeout=args.timeout,
    ) as uart:
        time.sleep(args.startup_delay)
        uart.reset_input_buffer()
        uart.reset_output_buffer()

        def reader() -> None:
            try:
                receive_result["data"] = receive_exact(uart, expected_output_bytes, args.timeout)
            except BaseException as error:
                receive_error["error"] = error

        receive_thread = threading.Thread(target=reader, daemon=True)
        receive_thread.start()

        header = bytes((CMD_MODE, args.mode, CMD_THRESHOLD, args.threshold, CMD_FRAME_START))
        uart.write(header)

        for start in range(0, len(payload), args.chunk_size):
            uart.write(payload[start:start + args.chunk_size])

        uart.flush()
        receive_thread.join(args.timeout + 5.0)

        if receive_thread.is_alive():
            raise TimeoutError("Receiver thread did not finish")

        if "error" in receive_error:
            raise receive_error["error"]

    output_data = receive_result["data"]
    write_mem_file(args.output, output_data)
    print(f"Sent {args.pixels} pixels from {args.input}")
    print(f"Received {args.pixels} processed pixels")
    print(f"Wrote {args.output}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", required=True)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=Path("processed_image.mem"))
    parser.add_argument("--mode", type=int, required=True)
    parser.add_argument("--threshold", type=int, required=True)
    parser.add_argument("--pixels", type=int, default=4800)
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--startup-delay", type=float, default=0.25)
    parser.add_argument("--chunk-size", type=int, default=1024)
    return parser


def main() -> None:
    parser = build_parser()
    transfer_image(parser.parse_args())


if __name__ == "__main__":
    main()
