# ⚠️ Deprecated

As of taskwarrior v3.0.0, `taskd` is not supported as a sync backend anymore [1], hence I'll discontinue this project.

[[1] https://taskwarrior.org/docs/upgrade-3/#upgrading-sync](https://taskwarrior.org/docs/upgrade-3/#upgrading-sync)

# docker-taskd
> container setup for [taskd](https://taskwarrior.org/docs/#taskd)

## Initialisation

When running the server for the first time, it will generate a config and certificate, unless they've been provided
already. It is important to set the
[variables for certificate generation](https://github.com/philipreinken/docker-taskd/blob/master/vars.template) in this
case, since the defaults

> are guaranteed to be wrong for you

to cite the [upstream setup guide](https://gothenburgbitfactory.github.io/taskserver-setup/).

Especially `TASKD_CN` should be set to the domain name of the server running `taskd`, otherwise the client will refuse
to connect. To do this, add `-e TASKD_CN="[your domain]"` to the `docker run` example [below](#running).

## Running

```bash
docker run -d -v taskd-data:/home/taskd/data -p 53589:53589 --name taskd philipreinken/docker-taskd
```

## Account Creation

Each account belongs to an organisation, so that has to be added first:

```bash
docker run --rm -v taskd-data:/home/taskd/data philipreinken/docker-taskd add-org 'Some Org'
```

The user account can then be added with reference to an existing organisation:

```bash
docker run --rm -v taskd-data:/home/taskd/data philipreinken/docker-taskd add-user 'Some Org' 'John Doe'
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
docker run --rm -v taskd-data:/home/taskd/data philipreinken/docker-taskd ca-cert > ~/.task/ca.cert.pem
```

### User certificate and key

To retrieve the user account certificate and key run:

```bash
docker run --rm -v taskd-data:/home/taskd/data philipreinken/docker-taskd user-cert 'u53r0C3rt1d0' > ~/.task/user.cert.pem
docker run --rm -v taskd-data:/home/taskd/data philipreinken/docker-taskd user-key 'u53r0C3rt1d0' > ~/.task/user.key.pem
```
