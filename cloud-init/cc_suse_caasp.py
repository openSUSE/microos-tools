# vi: ts=4 expandtab
#
#    Copyright (C) 2017 SUSE LLC
#
#    Author: Thorsten Kukuk <kukuk@suse.com>
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    in Version 2 or later as published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

from cloudinit.settings import PER_INSTANCE
from cloudinit import util

frequency = PER_INSTANCE

DEFAULT_PERMS = 0o644

# suse_caasp:
#  role: [admin|cluster]
#  admin_node: admin-node.example.com

def enable_service(service):
    cmd = ['systemctl', 'enable', '--now', service]
    util.subp(cmd, capture=True)

def handle(name, cfg, cloud, log, args):
    if len(args) != 0:
        caasp_cfg = util.read_conf(args[0])
    else:
        if 'suse_caasp' not in cfg:
            log.debug(("Skipping module named %s, "
                       "no 'suse_caasp' configuration found"), name)
            return
        caasp_cfg = cfg['suse_caasp']

    if 'role' not in caasp_cfg:
        log.warn(("Skipping module named %s, "
                  "no 'role' found in 'suse_caasp' configuration"), name)
        return
    system_role = caasp_cfg['role']

    if system_role == 'admin':
        log.debug(("role administration node found"))
        cmd = ['/usr/share/caasp-container-manifests/activate.sh']
        util.subp(cmd, capture=True)
        enable_service('admin-node-setup')
        enable_service('docker')
        enable_service('container-feeder')
        enable_service('etcd')
        enable_service('kubelet')
        enable_service('salt-minion')
    elif system_role == 'cluster':
        log.debug(("role cluster node found"))
        if 'admin_node' not in caasp_cfg:
            log.warn(("Skipping module named %s, "
                      "no 'admin_node' found for cluster system role"), name)
            return
        admin_node = caasp_cfg['admin_node']

        contents = "master: %s" % (admin_node)
        util.write_file('/etc/salt/minion.d/master.conf', contents, mode=DEFAULT_PERMS)
        sed_arg = "s|#NTP=.*|NTP=%s|g" % (admin_node)
        cmd = ['sed', '-i', '-e', sed_arg, '/etc/systemd/timesyncd.conf']
        util.subp(cmd, capture=True)

        enable_service('docker')
        enable_service('container-feeder')
        enable_service('salt-minion')
        enable_service('systemd-timesyncd')
    else:
        log.warn(("Unknown role %s, skipping module named %s"), role, name)
