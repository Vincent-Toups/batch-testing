::: {#content}
::: {#table-of-contents}
Table of Contents
-----------------

::: {#text-table-of-contents}
-   [1. Using Batch](#org7e3d48b)
-   [2. Making the Case for the az cli tool](#org3944dba)
-   [3. A CLI Tutorial](#org34687da)
-   [4. Notes About Usage](#org8dec3c9)
-   [5. C\# version](#orge5b1ed4)
:::
:::

::: {#outline-container-org7e3d48b .outline-2}
[1]{.section-number-2} Using Batch {#org7e3d48b}
----------------------------------

::: {#text-1 .outline-text-2}
Batch has a few interfaces.

1.  You can use it via the Azure Portal.
2.  via a C\# interface
3.  Or via the az command line application

Of these three the first leaves some things to be desired. To explain
why it may make sense to briefly consider a

> Glossary
>
> 1.  pool - a collection of cores on which your batch tasks actually
>     run
> 2.  job - a collection of tasks unified by some shared parameters
> 3.  task - some concrete computation which you want to distribute over
>     the pool
> 4.  application - a group of files (typically a script or app)
>     associated with a pool

Other notes:

The az command line utility speaks almost exclusively in JSON. I\'ve
used the [jq](https://stedolan.github.io/jq/) utility here and there to
extract fields from the results.

Typical usage for Batch involves uploading the data to a storage account
location, creating a job and then creating one or more tasks. These
tasks write to the same storage location they read from and then we
fetch the results.
:::
:::

::: {#outline-container-org3944dba .outline-2}
[2]{.section-number-2} Making the Case for the az cli tool {#org3944dba}
----------------------------------------------------------

::: {#text-2 .outline-text-2}
Of the three choices given above, I\'d like to make the case that its
best for our users to be trained to use the az cli tool. While the user
interface presented by the portal may offer some arguably usability
advantages, it is difficult to use it to launch a lot of tasks of a
similar nature.

The CLI and the C\# interface expose this possibility, but C\# is
outside the purview of most of our users (I would wager). The CLI can be
scripted with rudimentary bash scripting skills which I expect most HPC
users to have.
:::
:::

::: {#outline-container-org34687da .outline-2}
[3]{.section-number-2} A CLI Tutorial {#org34687da}
-------------------------------------

::: {#text-3 .outline-text-2}
We always begin by signing into Azure. This is a potential pain point in
a variety of ways.

1.  Users may be confused about which credentials to use given that we
    have have just had them log into their machine with a different set
    than their sso
2.  I\'m not actually sure how their batch credentials will align with
    either given the need to separate out batch accounts
3.  We\'ll need to restrict the IP addresses which we allow login from
    to keep people from trying to connect via their own installations of
    the Azure CLI

In any case, we log in by saying

::: {.org-src-container}
``` {.src .src-sh}
az login
```
:::

Which results in something [like]{.underline} this:

::: {.org-src-container}
``` {.src .src-sh}
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code <some-key> to authenticate.
```
:::

When you go through the single sign on you should see something like
this:

::: {.org-src-container}
``` {.src .src-sh}
[
  {
    "cloudName": "AzureCloud",
    "id": "********-****-****-****-************",
    "isDefault": true,
    "name": "UNC_RC_BACPAC_AAD",
    "state": "Enabled",
    "tenantId": "********-****-****-****-************",
    "user": {
      "name": "toups@ad.unc.edu",
      "type": "user"
    }
  }
]
```
:::

This is a surprisingly easy way to get set up. We can now interact with
batch.

To interact with batch itself we need to log in again to the batch
service. James has created an account for us to test with and we log in
like this:

::: {.org-src-container}
``` {.src .src-sh}
az batch account login --resource-group bacpacbatch --name kubetesting10192003ba
# once we have logged in we can list the available pools
az batch pool list | jq '.[].id'
```
:::

In this case there is just one. This is an ok representation of the
actual state of affairs that our users will meet - they will have a
pre-created batch user and pool.

Now we want to create a job, which is sort of like a
[container]{.underline} for tasks.

::: {.org-src-container}
``` {.src .src-sh}
export POOL=vincent
az batch job delete --job-id test-job 
az batch job create --id test-job --pool-id $POOL
az batch job list | jq '.[].id'
```
:::

Now that we have our job a simple embarassingly parallel job is launched
like this:

(we are pretending to mine bitcoin here).

::: {.org-src-container}
``` {.src .src-sh}
for i in $(seq 1 10); do 
    az batch task create \
    --task-id test-job-task-$i \
    --job-id test-job \
    --command-line "/bin/bash -c 'od -A n -t d -N 100000 /dev/urandom | md5sum'" | grep creationTime
done
```
:::

If we wanted to kill these tasks we could say:

::: {.org-src-container}
``` {.src .src-sh}
for i in $(seq 1 10); do 
    az batch task stop \
    --task-id my-job-$i \
    --job-id test-job 
done
```
:::

(Output is pretty voluminous and so we\'ve ellided it here).

I\'ve intentionally chosen a task which takes a little while to
complete.

::: {.org-src-container}
``` {.src .src-sh}
az batch task show --job-id test-job --task-id test-job-task-1 | jq ".executionInfo"
```
:::

Now we just wait for it to finish. We could poll the tasks via a small
script if we wanted to monitor them.

::: {.org-src-container}
``` {.src .src-sh}
az batch task file list \
    --job-id test-job \
    --task-id test-job-task-1 \
    --output table
```
:::

Let\'s get those delicious hashes.

::: {.org-src-container}
``` {.src .src-sh}
for i in $(seq 1 10); do 
    az batch task file download \
    --task-id test-job-task-$i \
    --job-id test-job \
    --destination ./test-job-task-$i-stdout.txt \
    --file-path stdout.txt
    cat ./test-job-task-$i-stdout.txt
done
```
:::
:::
:::

::: {#outline-container-org8dec3c9 .outline-2}
[4]{.section-number-2} Notes About Usage {#org8dec3c9}
----------------------------------------

::: {#text-4 .outline-text-2}
The environment in which jobs run needs to be customized to a degree.
The operating system and libraries are set up ahead of time in Azure and
we should try our best to make the linux system which hosts task
execution as close to the virtual machines as possible.

Jobs may need custom files.

In order to access them you create an application, which despite its
name, may contain things other than just executables.

::: {.org-src-container}
``` {.src .src-sh}
az batch application create \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application"

# An application can reference multiple application executable packages
# of different versions. The executables and any dependencies need
# to be zipped up for the package. Once uploaded, the CLI attempts
# to activate the package so that it's ready for use.
az batch application package create \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application" \
    --package-file my-application-exe.zip \
    --version-name 1.0

# Update the application to assign the newly added application
# package as the default version.
az batch application set \
    --resource-group myResourceGroup \
    --name mybatchaccount \
    --application-name "My Application" \
    --default-version 1.0
```
:::

Another possibility is to use the --resource-files switch when you
create the task.

I believe we will need to configure the batch machines to mount the
appropriate storage locations for BACPAC data if we want to do that.
:::
:::

::: {#outline-container-orge5b1ed4 .outline-2}
[5]{.section-number-2} C\# version {#orge5b1ed4}
----------------------------------

::: {#text-5 .outline-text-2}
You can see a similar project via C\#
[here](https://github.com/Azure-Samples/batch-dotnet-ffmpeg-tutorial).
:::
:::
:::

::: {#postamble .status}
Author: Vincent

Created: 2020-11-05 Thu 15:04

[Validate](http://validator.w3.org/check?uri=referer)
:::
