<%
import pwnlib.shellcraft as sc
import pwnlib.abi as abi
%>
<%docstring>epoll_ctl(epfd, op, fd, event) -> str

Invokes the syscall epoll_ctl.

See 'man 2 epoll_ctl' for more information.

Arguments:
    epfd(int): epfd
    op(int): op
    fd(int): fd
    event(epoll_event*): event
Returns:
    int
</%docstring>
<%page args="epfd, op, fd, event"/>
<%
    abi = abi.ABI.syscall()
    stack = abi.stack
    regs = abi.register_arguments[1:]
    allregs = sc.registers.current()

    can_pushstr = []
    can_pushstr_array = []

    argument_names = ['epfd', 'op', 'fd', 'event']
    argument_values = [epfd, op, fd, event]

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
    /* epoll_ctl(epfd=${repr(epfd)}, op=${repr(op)}, fd=${repr(fd)}, event=${repr(event)}) */
    ${sc.setregs(register_arguments)}
%for name, arg in string_arguments.items():
    ${sc.pushstr(arg, append_null=('\x00' not in arg))}
    ${sc.mov(regs[argument_names.index(name)], abi.stack)}
%endfor
%for name, arg in array_arguments.items():
    ${sc.pushstr_array(regs[argument_names.index(name)], arg)}
%endfor
    ${sc.syscall('SYS_epoll_ctl')}