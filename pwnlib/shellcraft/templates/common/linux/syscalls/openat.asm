<%
import collections
import pwnlib.abi
import pwnlib.constants
import pwnlib.shellcraft
%>
<%docstring>openat(fd, file, oflag, vararg_0, vararg_1, vararg_2, vararg_3, vararg_4) -> str

Invokes the syscall openat.

See 'man 2 openat' for more information.

Arguments:
    fd(int): fd
    file(char*): file
    oflag(int): oflag
    vararg(int): vararg
Returns:
    int
</%docstring>
<%page args="fd=0, file=0, oflag=0, vararg_0=None, vararg_1=None, vararg_2=None, vararg_3=None, vararg_4=None"/>
<%
    abi = pwnlib.abi.ABI.syscall()
    stack = abi.stack
    regs = abi.register_arguments[1:]
    allregs = pwnlib.shellcraft.registers.current()

    can_pushstr = ['file']
    can_pushstr_array = []

    argument_names = ['fd', 'file', 'oflag', 'vararg_0', 'vararg_1', 'vararg_2', 'vararg_3', 'vararg_4']
    argument_values = [fd, file, oflag, vararg_0, vararg_1, vararg_2, vararg_3, vararg_4]

    # Load all of the arguments into their destination registers / stack slots.
    register_arguments = dict()
    stack_arguments = collections.OrderedDict()
    string_arguments = dict()
    dict_arguments = dict()
    array_arguments = dict()

    for name, arg in zip(argument_names, argument_values):
        # If the argument itself (input) is a register...
        if arg in allregs:
            index = argument_names.index(name)
            if index < len(regs):
                target = regs[index]
                register_arguments[target] = arg
            elif arg is not None:
                stack_arguments[index] = arg

        # The argument is not a register.  It is a string value, and we
        # are expecting a string value
        elif name in can_pushstr and isinstance(arg, str):
            string_arguments[name] = arg

        # The argument is not a register.  It is a dictionary, and we are
        # expecting K:V paris.
        elif name in can_pushstr_array and isinstance(arg, dict):
            array_arguments[name] = ['%s=%s' % (k,v) for (k,v) in arg.items()]

        # The arguent is not a register.  It is a list, and we are expecting
        # a list of arguments.
        elif name in can_pushstr_array and isinstance(arg, (list, tuple)):
            array_arguments[name] = arg

        # The argument is not a register, string, dict, or list.
        # It could be a constant string ('O_RDONLY') for an integer argument,
        # an actual integer value, or a constant.
        else:
            index = argument_names.index(name)
            if index < len(regs):
                target = regs[index]
                register_arguments[target] = arg
            elif arg is not None:
                stack_arguments[target] = arg

    # Some syscalls have different names on various architectures.
    # Determine which syscall number to use for the current architecture.
    for syscall in ['SYS_openat']:
        if hasattr(pwnlib.constants, syscall):
            break
    else:
        raise Exception("Could not locate any syscalls: %r" % syscalls)
%>
    /* openat(fd=${repr(fd)}, file=${repr(file)}, oflag=${repr(oflag)}, vararg_0=${repr(vararg_0)}, vararg_1=${repr(vararg_1)}, vararg_2=${repr(vararg_2)}, vararg_3=${repr(vararg_3)}, vararg_4=${repr(vararg_4)}) */
%for name, arg in string_arguments.items():
    ${pwnlib.shellcraft.pushstr(arg, append_null=('\x00' not in arg))}
    ${pwnlib.shellcraft.mov(regs[argument_names.index(name)], abi.stack)}
%endfor
%for name, arg in array_arguments.items():
    ${pwnlib.shellcraft.pushstr_array(regs[argument_names.index(name)], arg)}
%endfor
%for name, arg in stack_arguments.items():
    ${pwnlib.shellcraft.push(arg)}
%endfor
    ${pwnlib.shellcraft.setregs(register_arguments)}
    ${pwnlib.shellcraft.syscall(syscall)}