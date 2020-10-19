Azure Batch Experimentation
===========================

Building the Docker Image
-------------------------

```
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc
docker build . -t batch-experimentation
```

Running it:

```
docker run -v $(pwd):/host -it batch-experimentation

```

Once in the container you'll have to login by saying 

```
az login
```

Follow the instructions.

