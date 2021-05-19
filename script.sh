#!/bin/bash

# First we log into the system this requires us to open a browser
# somewhere and sign in with the appropriate credentials.  I'm not yet
# clear on what these will be relative to the credentials we are using
# for our VMs.

az login 

# Then we need to log in to the batch account we want to use.  James
# set this up for me.  If he hadn't we'd have to do a few more
# commands to create an account and a pool but I believe these will be
# handled ahead of time for our users anyway so I am content to test
# it out this way as well.
az batch account login --resource-group bacpacbatch --name kubetesting10192003ba
export POOL=`az batch pool list | jq '.[0]["id"]'`

# Now some termin
