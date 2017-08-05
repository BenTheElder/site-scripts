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

Use at your own risk.

GCE bootstrap script
'''
from __future__ import print_function
import os
import sys
try:
    input = raw_input
except NameError:
    pass


def get_setting(env_key, description):
    if env_key in os.environ:
        print("Got %s from env." % (description))
        return os.environ[env_key]
    else:
        return input("%s: " % (description))


def main():
    """interactively run gce bootstrap script with environment variables set"""
    self_path = os.path.dirname(__file__)
    project_path = os.path.join(self_path, "..")
    os.chdir(project_path)
    print("enter environment variable values")
    email = get_setting("EMAIL", "email")
    cloudflare_key = get_setting("CLOUDFLARE_API_KEY", "cloudflare api key")
    caddy_domain_name = get_setting("DOMAIN_NAME", "domain name")
    git_hook_key = get_setting("GIT_HOOK_KEY_SITE", "git hook (site) key")
    git_hook_key2 = get_setting("GIT_HOOK_KEY_OLIVAW", "git hook (olivaw) key")
    caddy_env = (
        'Environment=CADDY_DOMAIN_NAME=%s\n'
        'Environment=CADDY_GIT_HOOK_KEY_SITE=%s\n'
        'Environment=CADDY_GIT_HOOK_KEY_OLIVAW=%s\n'
        'Environment=CLOUDFLARE_EMAIL=%s\n'
        'Environment=CLOUDFLARE_API_KEY=%s\n'
    ) % (caddy_domain_name, git_hook_key, git_hook_key2, email, cloudflare_key)
    env = 'CADDY_EMAIL="%s" CADDY_ENV="%s"' % (email, caddy_env)
    os.system(env+" sh ./gce/bootstrap.sh")

if __name__ == "__main__":
    main()
