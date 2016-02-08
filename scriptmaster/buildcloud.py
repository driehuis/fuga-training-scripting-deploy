#!/usr/bin/env python

from novaclient import client
import os
import pprint
import re
import sys
import time


# Constants
NOVA_API_VERSION = "2"
# Regex to match the image we need
ubuntu_image_match = r"ubuntu 14.04.3.*image"
desired_flavor = "c1.micro"

# Utility routines


def die(str):
    print "Fatal: " + str
    sys.exit(1)


def getenv_mandatory(str):
    """Get a value from the environment or give up."""
    val = os.environ.get(str)
    if val is None:
        die("could not fetch ' + str + ' from the environment. " +
            "Did you forget to source your credentials file?")
    return val


def list_find(list, name):
    for o in list:
        if o.name == name:
            return o
    return None


def list_find_regex(list, regex_s):
    regex = re.compile(regex_s, re.IGNORECASE)
    for o in list:
        if regex.match(o.name):
            return o
    return None


def wait_for_server_creation(nova, name):
    delay = 0.2
    while delay < 120.0:
        serverlist = nova.servers.list()
        server = list_find(serverlist, name)
        if not server is None and server.status == 'ACTIVE':
            return
        print "Waiting " + str(delay) + " seconds for " + name + " to become active"
        delay *= 1.5
        time.sleep(delay)
    die("Server " + name + " dit not become available in a reasonable time")

# Collect all relevant authentication parameters
os_username = getenv_mandatory('OS_USERNAME')
os_password = getenv_mandatory('OS_PASSWORD')
os_tenant_id = getenv_mandatory('OS_TENANT_ID')
os_tenant_name = getenv_mandatory('OS_TENANT_NAME')
os_auth_url = getenv_mandatory('OS_AUTH_URL')

pp = pprint.PrettyPrinter(indent=4)

# Set up communications with Nova
nova = client.Client(NOVA_API_VERSION, os_username, os_password,
                     os_tenant_name, os_auth_url)

# Get the current list of servers, images and flavors
serverlist = nova.servers.list()
imagelist = nova.images.list()
flavorlist = nova.flavors.list()
image = list_find_regex(imagelist, ubuntu_image_match)
if image is None:
    die("Could not find an image matching " + ubuntu_image_match)
#pp.pprint(image)
flavor = list_find(flavorlist, desired_flavor)
if flavor is None:
    die("Could not find a flavor matching " + desired_flavor)
#pp.pprint(flavor)

scriptmaster = list_find(serverlist, "scriptmaster")
if scriptmaster is None:
    print("Creating server scriptmaster")
    nova.servers.create("scriptmaster", image, flavor)
    wait_for_server_creation(nova, "scriptmaster")

#pp.pprint(serverlist[0])
#pp.pprint(scriptmaster)
sys.exit(0)
imagelist = nova.images.list()
pp.pprint(imagelist)
