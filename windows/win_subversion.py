#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2015, Mick McGrellis <mpmcgrellis@gmail.com>
#
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_subversion
version_added: "2.0"
short_description: Deploys a subversion repository.
description:
  - Deploy given repository URL / revision to C(dest). If C(dest) exists, update to the specified C(revision), otherwise perform a checkout.  Like the M(subversion) module, but for Windows.
author: "Mick McGrellis <mpmcgrellis@gmail.com>"
note:
  - Requires I(svn) to be installed on the client.  You can use M(win_chocolatey) to do that.
requirements: []
options:
  repo:
    description:
      - The subversion URL to the repository.
    required: true
    aliases: [ name, repository ]
    default: null
  dest:
    description:
      - Absolute path where the repository should be deployed.
    required: true
    default: null
  revision:
    description:
      - Specific revision to checkout.
    required: false
    default: HEAD
    aliases: [ version ]
  force:
    description:
      - If C(yes), modified files will be discarded. If C(no), module will fail if it encounters modified files.
    required: false
    default: "no"
    choices: [ "yes", "no" ]
  username:
    description:
      - --username parameter passed to svn.
    required: false
    default: null
  password:
    description:
      - --password parameter passed to svn.
    required: false
    default: null
    no_log: true
  executable:
    required: false
    default: null
    description:
      - Path to svn executable to use. If not supplied,
        the normal mechanism for resolving binary paths will be used.
  export:
    required: false
    default: "no"
    choices: [ "yes", "no" ]
    description:
      - If C(yes), do export instead of checkout/update.
  switch:
    required: false
    default: "yes"
    choices: [ "yes", "no" ]
    description:
      - If C(no), do not call svn switch before update.
'''

EXAMPLES = '''
# Checkout subversion repository to specified folder.
- win_subversion: repo=svn+ssh://an.example.org/path/to/repo dest=C:\src\checkout
# Export subversion directory to folder
- win_subversion: repo=svn+ssh://an.example.org/path/to/repo dest=C:\src\export export=True
'''
