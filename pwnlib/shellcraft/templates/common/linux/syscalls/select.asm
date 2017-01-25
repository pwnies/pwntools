<%
import pwnlib.shellcraft as sc
import pwnlib.abi as abi
%>
<%docstring>select(nfds, readfds, writefds, exceptfds, timeout) -> str

Invokes the syscall select.

See 'man 2 select' for more information.

Arguments:
    nfds(int): nfds
    readfds(fd_set*): readfds
    writefds(fd_set*): writefds
    exceptfds(fd_set*): exceptfds
    timeout(timeval*): timeout
Returns:
    int
</%docstring>
<%page args="nfds, readfds, writefds, exceptfds, timeout"/>
<%
    abi = abi.ABI.syscall()
    stack = abi.stack
    regs = abi.register_arguments[1:]
    allregs = sc.registers.current()

    can_pushstr = []
    can_pushstr_array = []

    argument_names = ['nfds', 'readfds', 'writefds', 'exceptfds', 'timeout']
    argument_values = [nfds, readfds, writefds, exceptfds, timeout]

    # Figure out which register arguments can be set immediately
    register_arguments = dict()
    string_arguments = dict()
    dict_arguments = dict()
    array_arguments = dict()

    for name, arg in zip(argument_names, argument_values):
        if arg in allregs:
            index = argument_names.index(name)
            target = regs[index]
            register_arguments[target] = arg
        elif name in can_pushstr and isinstance(arg, str):
            string_arguments[name] = arg
        elif name in can_pushstr_array and isinstance(arg, dict):
            array_arguments[name] = ['%s=%s' % (k,v) for (k,v) in arg.items()]
        elif name in can_pushstr_array and isinstance(arg, (list, tuple)):
            array_arguments[name] = arg
        else:
            index = argument_names.index(name)
            target = regs[index]
            register_arguments[target] = arg
%>
    /* select(nfds=${repr(nfds)}, readfds=${repr(readfds)}, writefds=${repr(writefds)}, exceptfds=${repr(exceptfds)}, timeout=${repr(timeout)}) */
    ${sc.setregs(register_arguments)}
%for name, arg in string_arguments.items():
    ${sc.pushstr(arg, append_null=('\x00' not in arg))}
    ${sc.mov(regs[argument_names.index(name)], abi.stack)}
%endfor
%for name, arg in array_arguments.items():
    ${sc.pushstr_array(regs[argument_names.index(name)], arg)}
%endfor
    ${sc.syscall('SYS_select')}