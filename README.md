# docker-taskd
> container setup for [taskd](https://taskwarrior.org/docs/#taskd)

## running

```bash
docker run -d -v taskd-data:/home/taskd/data -p 53589:53589 --name taskd taskd
```

## account creation

Each account belongs to an organisation, so that has to be added first:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd --add-org 'some-org'
```

The user account can then be added with reference to an existing organisation:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd --add-user 'some-org' 'john-doe'
```

## client configuration

To get the servers CA certificate run:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd --ca-cert > ~/.task/ca.cert.pem
```

To get the user account certificate and key run:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd --user-cert 'john-doe' > ~/.task/user.cert.pem
docker run --rm -v taskd-data:/home/taskd/data taskd --user-key 'john-doe' > ~/.task/user.key.pem
```
