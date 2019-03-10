# docker-taskd
> container setup for [taskd](https://taskwarrior.org/docs/#taskd)

## Running

```bash
docker run -d -v taskd-data:/home/taskd/data -p 53589:53589 --name taskd taskd
```

## Account Creation

Each account belongs to an organisation, so that has to be added first:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd add-org 'Some Org'
```

The user account can then be added with reference to an existing organisation:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd add-user 'Some Org' 'John Doe'
```

The `add-user` command is a wrapper around the taskservers built-in `add user`
command which adds the user and generates the necessary client certificate:

```
ORG                 	USERNAME            	KEY                                     	USER-CERT
Some Org            	John Doe            	0thisisa-uuid-uuid-uuid-onetwothree4    	u53r0C3rt1d0
```

The certificate is saved and may be retrieved and/or deleted [later on](#user-certificate-and-key)
using the value provided in the `USER-CERT` column.

## Client Configuration

### Server CA certificate

To retrieve the servers CA certificate run:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd ca-cert > ~/.task/ca.cert.pem
```

### User certificate and key

To retrieve the user account certificate and key run:

```bash
docker run --rm -v taskd-data:/home/taskd/data taskd user-cert 'u53r0C3rt1d0' > ~/.task/user.cert.pem
docker run --rm -v taskd-data:/home/taskd/data taskd user-key 'u53r0C3rt1d0' > ~/.task/user.key.pem
```
