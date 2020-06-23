#!/usr/bin/env python
from __future__ import absolute_import
from __future__ import division

import os
import subprocess

import pwnlib
pwnlib.args.free_form = False

from pwn import *
from pwnlib.commandline import common

parser = common.parser_commands.add_parser(
    'version',
    help = 'Pwntools version'
)

def main(a):
	version = pwnlib.version

	git_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
	if os.path.exists(os.path.join(git_root, '.git')):
		gitver = subprocess.check_output(['git', '-C',  git_root, 'log', '-1', '--format=%h (%cr)'])
		version = '%s-%s' % (version, gitver.decode())

	log.info("Pwntools v%s" % version)

if __name__ == '__main__':
    pwnlib.commandline.common.main(__file__)
