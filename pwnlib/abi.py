# -*- coding: utf-8 -*-
from __future__ import absolute_import

from pwnlib.context import LocalContext
from pwnlib.context import context


class ABI(object):
    """
    Encapsulates information about a calling convention.
    """
    #: List or registers which should be filled with arguments before
    #: spilling onto the stack.
    register_arguments = []

    #: Minimum alignment of the stack.
    #: The value used is min(context.bytes, stack_alignment)
    #: This is necessary as Windows x64 frames must be 32-byte aligned.
    #: "Alignment" is considered with respect to the last argument on the stack.
    arg_alignment    = 1

    #: Minimum number of stack slots used by a function call
    #: This is necessary as Windows x64 requires using 4 slots on the stack
    stack_minimum      = 0

    #: Indicates that this ABI returns to the next address on the slot
    returns            = True

    def __init__(self, stack, regs, align, minimum):
        self.stack              = stack
        self.register_arguments = regs
        self.arg_alignment      = align
        self.stack_minimum      = minimum

    @staticmethod
    @LocalContext
    def default():
        if context.os == 'android':
            context.os = 'linux'

        return {
        (32, 'i386', 'linux'):  linux_i386,
        (64, 'amd64', 'linux'): linux_amd64,
        (32, 'arm', 'linux'):   linux_arm,
        (32, 'thumb', 'linux'):   linux_arm,
        (32, 'mips', 'linux'):   linux_mips,
        (32, 'i386', 'windows'):  windows_i386,
        (64, 'amd64', 'windows'): windows_amd64,
        }[(context.bits, context.arch, context.os)]

    @staticmethod
    @LocalContext
    def syscall():
        if context.os == 'android':
            context.os = 'linux'

        return {
        (32, 'i386', 'linux'):  linux_i386_syscall,
        (64, 'amd64', 'linux'): linux_amd64_syscall,
        (32, 'arm', 'linux'):   linux_arm_syscall,
        (32, 'thumb', 'linux'):   linux_arm_syscall,
        (32, 'mips', 'linux'):   linux_mips_syscall,
        (64, 'aarch64', 'linux'):   linux_aarch64_syscall,
        }[(context.bits, context.arch, context.os)]

    @staticmethod
    @LocalContext
    def sigreturn():
        if context.os == 'android':
            context.os = 'linux'

        return {
        (32, 'i386', 'linux'):  linux_i386_sigreturn,
        (64, 'amd64', 'linux'): linux_amd64_sigreturn,
        (32, 'arm', 'linux'):   linux_arm_sigreturn,
        (32, 'thumb', 'linux'):   linux_arm_sigreturn,
        (64, 'aarch64', 'linux'):   linux_aarch64_sigreturn,
        }[(context.bits, context.arch, context.os)]

class SyscallABI(ABI):
    """
    The syscall ABI treats the syscall number as the zeroth argument,
    which must be loaded into the specified register.
    """
    def __init__(self, *a, **kw):
        super(SyscallABI, self).__init__(*a, **kw)
        self.syscall_register = self.register_arguments[0]

class SigreturnABI(SyscallABI):
    """
    The sigreturn ABI is similar to the syscall ABI, except that
    both PC and SP are loaded from the stack.  Because of this, there
    is no 'return' slot necessary on the stack.
    """
    returns = False


linux_i386   = ABI('esp', [], 4, 0)
linux_amd64  = ABI('rsp', ['rdi','rsi','rdx','rcx','r8','r9'], 8, 0)
linux_arm    = ABI('sp', ['r0', 'r1', 'r2', 'r3'], 8, 0)
linux_aarch64 = ABI('sp', ['x0', 'x1', 'x2', 'x3'], 16, 0)
linux_mips  = ABI('$sp', ['$a0','$a1','$a2','$a3'], 4, 0)

linux_i386_syscall = SyscallABI('esp', ['eax', 'ebx', 'ecx', 'edx', 'esi', 'edi', 'ebp'], 4, 0)
linux_amd64_syscall = SyscallABI('rsp', ['rax', 'rdi', 'rsi', 'rdx', 'r10', 'r8', 'r9'],   8, 0)
linux_arm_syscall   = SyscallABI('sp', ['r7', 'r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6'], 4, 0)
linux_aarch64_syscall   = SyscallABI('sp', ['x8', 'x0', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6'], 16, 0)
linux_mips_syscall  = SyscallABI('$sp', ['$v0','$a0','$a1','$a2','$a3'], 4, 0)

linux_i386_sigreturn = SigreturnABI('esp', ['eax'], 4, 0)
linux_amd64_sigreturn = SigreturnABI('rsp', ['rax'], 4, 0)
linux_arm_sigreturn = SigreturnABI('sp', ['r7'], 4, 0)
linux_aarch64_sigreturn = SigreturnABI('sp', ['x8'], 16, 0)

windows_i386  = ABI('esp', [], 4, 0)
windows_amd64 = ABI('rsp', ['rcx','rdx','r8','r9'], 32, 32)

# Fake ABIs used by SROP
linux_i386_srop = ABI('esp', ['eax'], 4, 0)
linux_amd64_srop = ABI('rsp', ['rax'], 4, 0)
linux_arm_srop = ABI('sp', ['r7'], 4, 0)
