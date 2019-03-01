# docker-taskd
> container setup for [taskd](https://taskwarrior.org/docs/#taskd)

## running

```bash
docker run -d -v taskd-data:/home/taskd/data -p 53589:53589 --name taskd taskd
```
