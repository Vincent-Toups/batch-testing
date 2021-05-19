FROM ubuntu:20.04
RUN apt-get update -y && apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
COPY microsoft.asc /etc/apt/trusted.gpg.d/microsoft.gpg 
RUN apt-get update -y && apt-get install -y azure-cli
RUN apt-get update -y && apt-get install -y jq emacs
WORKDIR /host
CMD /bin/bash

