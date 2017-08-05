#!/usr/bin/env python
'''
Copyright 2016-2017 Benjamin Elder (BenTheElder) All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Deploys to Google Compute Engine
Use at your own risk.
'''
from __future__ import print_function
import sys
import os
import subprocess
try:
    input = raw_input
except NameError:
    pass


# http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python
def eprint(*args, **kwargs):
    """like print_function but to stderr"""
    print(*args, file=sys.stderr, **kwargs)


def run_and_check(cmd, env=None):
    if env is None:
        env = os.environ.copy()
    """runs cmd with system and prints an error if the command fails"""
    res = subprocess.Popen(cmd, stdout=sys.stdout, stderr=sys.stderr, env=env)
    if res != 0:
        eprint("Command failed!")
        eprint(cmd)


def main(args):
    """deploys BenTheElder's site to GCE"""
    self_path = os.path.dirname(__file__)
    project_path = os.path.join(self_path, "..")
    os.chdir(project_path)
    if '-y' in args:
        choice = "yes"
    else:
        # make sure user agrees to run this
        choice = input((
            "Use this at your own risk; this will use gcloud to deploy.\n"
            "Please confirm 'yes' or 'no': "
        ))
    if choice == 'no':
        print("Aborting on 'no'")
        return
    elif choice != 'yes':
        print("Please respond with 'yes' or 'no'; Aborting")
        return
    startup = 'gce/startup.sh'
    if 'STARTUP' in os.environ:
        startup = os.environ['STARTUP']
    # create instance
    run_and_check((
        'gcloud compute instances create olivaw-instance \\'
        '--image-family=ubuntu-1604-lts \\'
        '--image-project=ubuntu-os-cloud \\'
        '--machine-type=f1-micro \\'
        '--scopes userinfo-email,cloud-platform \\'
        '--metadata-from-file startup-script=%s \\'
        '--zone us-central1-f \\'
        '--tags http-server'
    ) % (startup))
    # open ports 80 and 443
    run_and_check((
        'gcloud compute firewall-rules create default-allow-http \\'
        '--allow tcp:80 \\'
        '--source-ranges 0.0.0.0/0 \\'
        '--target-tags http-server \\'
        '--description "Allow port 80 access to http-server"'
    ))
    run_and_check((
        'gcloud compute firewall-rules create default-allow-https \\'
        '--allow tcp:443 \\'
        '--source-ranges 0.0.0.0/0 \\'
        '--target-tags http-server \\'
        '--description "Allow port 443 access to http-server"'
    ))
    print("Done.")

if __name__ == "__main__":
    main(sys.argv)
