<%
import pwnlib.shellcraft as sc
import pwnlib.abi as abi
%>
<%docstring>remap_file_pages(start, size, prot, pgoff, flags) -> str

Invokes the syscall remap_file_pages.

See 'man 2 remap_file_pages' for more information.

Arguments:
    start(void*): start
    size(size_t): size
    prot(int): prot
    pgoff(size_t): pgoff
    flags(int): flags
Returns:
    int
</%docstring>
<%page args="start, size, prot, pgoff, flags"/>
<%
    abi = abi.ABI.syscall()
    stack = abi.stack
    regs = abi.register_arguments[1:]
    allregs = sc.registers.current()

    can_pushstr = []
    can_pushstr_array = []

    argument_names = ['start', 'size', 'prot', 'pgoff', 'flags']
    argument_values = [start, size, prot, pgoff, flags]

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
    /* remap_file_pages(start=${repr(start)}, size=${repr(size)}, prot=${repr(prot)}, pgoff=${repr(pgoff)}, flags=${repr(flags)}) */
    ${sc.setregs(register_arguments)}
%for name, arg in string_arguments.items():
    ${sc.pushstr(arg, append_null=('\x00' not in arg))}
    ${sc.mov(regs[argument_names.index(name)], abi.stack)}
%endfor
%for name, arg in array_arguments.items():
    ${sc.pushstr_array(regs[argument_names.index(name)], arg)}
%endfor
    ${sc.syscall('SYS_remap_file_pages')}