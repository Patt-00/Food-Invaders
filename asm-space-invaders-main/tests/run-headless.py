#!/usr/bin/env python3
"""Run assembled DOS tests in Unicorn; BIOS/DOS services are minimal stubs.

This executes the actual x86 code and checks VGA memory, but does not validate
DOSBox-X video timing, host window output, or physical keyboard behavior.
Install the optional `unicorn` Python package and pass one or more COM paths.
"""

import struct
import sys
from pathlib import Path

from unicorn import Uc, UC_ARCH_X86, UC_MODE_16, UC_HOOK_INTR, UC_HOOK_INSN
from unicorn.x86_const import (
    UC_X86_REG_AX, UC_X86_REG_BX, UC_X86_REG_CX, UC_X86_REG_DX,
    UC_X86_REG_CS, UC_X86_REG_DS, UC_X86_REG_ES, UC_X86_REG_SS,
    UC_X86_REG_ESP, UC_X86_REG_EFLAGS, UC_X86_INS_IN, UC_X86_INS_OUT,
)


def run(path):
    machine = Uc(UC_ARCH_X86, UC_MODE_16)
    machine.mem_map(0, 2 * 1024 * 1024)
    binary = path.read_bytes()
    if len(binary) >= 60000:
        raise ValueError(f"{path}: COM exceeds the project's stack budget")
    machine.mem_write(0x10100, binary)
    for register in (UC_X86_REG_CS, UC_X86_REG_DS, UC_X86_REG_ES, UC_X86_REG_SS):
        machine.reg_write(register, 0x1000)
    machine.reg_write(UC_X86_REG_ESP, 0xFFFE)
    keyboard = []
    output = []
    exit_code = None

    def flags(mask, enabled):
        value = machine.reg_read(UC_X86_REG_EFLAGS)
        machine.reg_write(UC_X86_REG_EFLAGS, value | mask if enabled else value & ~mask)

    def interrupt(cpu, number, _):
        nonlocal exit_code
        ax = cpu.reg_read(UC_X86_REG_AX)
        ah = ax >> 8
        dx = cpu.reg_read(UC_X86_REG_DX)
        if number == 0x21:
            address = cpu.reg_read(UC_X86_REG_DS) * 16 + dx
            if ah == 0x4C:
                exit_code = ax & 0xFF
                cpu.emu_stop()
            elif ah == 0x09:
                data = bytes(cpu.mem_read(address, 65536 - dx)).split(b"$", 1)[0]
                output.append(data.decode("ascii", errors="replace"))
            elif ah == 0x40:
                length = cpu.reg_read(UC_X86_REG_CX)
                output.append(bytes(cpu.mem_read(address, length)).decode("ascii", errors="replace"))
                cpu.reg_write(UC_X86_REG_AX, length)
                flags(1, False)
            else:
                raise RuntimeError(f"Unsupported DOS service {ax:04x}")
        elif number == 0x10:
            if ax == 0x4F02:
                if cpu.reg_read(UC_X86_REG_BX) != 0x010C:
                    raise RuntimeError("Unexpected VESA mode")
                cpu.mem_write(0x44A, struct.pack("<H", 132))
                cpu.reg_write(UC_X86_REG_AX, 0x004F)
            elif ax == 3:
                cpu.mem_write(0x44A, struct.pack("<H", 80))
                cpu.mem_write(0x484, bytes([24]))
            elif ah != 1:
                raise RuntimeError(f"Unsupported video service {ax:04x}")
        elif number == 0x15 and ah == 0x86:
            flags(1, False)
        elif number == 0x1A and ah == 0x00:
            cpu.reg_write(UC_X86_REG_CX, 0x1234)
            cpu.reg_write(UC_X86_REG_DX, 0x5678)
            cpu.reg_write(UC_X86_REG_AX, 0)
            flags(1, False)
        elif number == 0x16:
            if ah == 5:
                keyboard.append(cpu.reg_read(UC_X86_REG_CX))
                cpu.reg_write(UC_X86_REG_AX, ax & 0xFF00)
            elif ah == 1:
                flags(0x40, not keyboard)
                if keyboard:
                    cpu.reg_write(UC_X86_REG_AX, keyboard[0])
            elif ah == 0 and keyboard:
                cpu.reg_write(UC_X86_REG_AX, keyboard.pop(0))
            else:
                raise RuntimeError("Unexpected blocking keyboard read")
        else:
            raise RuntimeError(f"Unsupported interrupt {number:02x}, AX={ax:04x}")

    machine.hook_add(UC_HOOK_INTR, interrupt)
    machine.hook_add(UC_HOOK_INSN, lambda cpu, port, size, data: 0, None, 1, 0, UC_X86_INS_IN)
    machine.hook_add(UC_HOOK_INSN, lambda cpu, port, size, value, data: None, None, 1, 0, UC_X86_INS_OUT)
    machine.emu_start(0x10100, 0x200000, timeout=50_000_000, count=100_000_000)
    message = "".join(output).strip()
    print(f"{path.name}: {message or 'no test output'}")
    if exit_code is None:
        raise RuntimeError("Test did not exit within the instruction/time budget")
    if exit_code or not message.startswith("PASS"):
        raise RuntimeError(f"Test failed with DOS exit status {exit_code}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Usage: python3 tests/run-headless.py TEST.COM PBTEST.COM COLLTEST.COM")
    failures = 0
    for argument in sys.argv[1:]:
        try:
            run(Path(argument))
        except RuntimeError as error:
            print(f"{Path(argument).name}: {error}", file=sys.stderr)
            failures += 1
    sys.exit(1 if failures else 0)
