# Personal deployment

This fork runs the self-hosted Executor (`apps/host-selfhost`) in Docker on my
own server. Everything here sits in `personal/` so upstream merges stay
conflict-free.

## First run

Needs git, Docker with the compose plugin, and curl on the server.

```sh
git clone https://github.com/MylesMCook/executor.git
cd executor
cp apps/host-selfhost/.env.example apps/host-selfhost/.env
```

Edit `apps/host-selfhost/.env` and set `EXECUTOR_WEB_BASE_URL` to the exact
address you will open in the browser, for example
`http://192.168.1.50:4788` or `https://executor.example.com`. Browser logins
are rejected when it does not match. Everything else is optional.

```sh
./personal/deploy.sh
```

This pulls upstream's prebuilt image (`linux/arm64` and `amd64`). Building from
source inside Docker installs the whole monorepo and can take a very long time
on a Mac, so only use `./personal/deploy.sh --build` once this fork carries its
own code changes. The prebuilt path needs Docker Compose 2.24 or newer.

Open the base URL. The first account you create becomes the owner, and
self-service signup closes after that.

The prebuilt deploy binds port 4788 to `127.0.0.1` only. Publish it on the
tailnet over HTTPS with Tailscale Serve, and set `EXECUTOR_WEB_BASE_URL` to the
resulting `https://<machine>.<tailnet>.ts.net` address:

```sh
tailscale serve --bg 4788
```

## Connect an agent

```sh
npx add-mcp http://<server>:4788/mcp --transport http --name executor
```

The **Connect** card in the web UI shows the exact command.

## Update

Pull upstream into the fork (GitHub's **Sync fork** button, or
`git fetch upstream && git merge upstream/main` with
`upstream` = `https://github.com/UsefulSoftwareCo/executor.git`), then on the
server:

```sh
./personal/deploy.sh
```

Data lives in the `host-selfhost_executor-data` volume and survives rebuilds.

## Back up

SQLite should not be copied while it is being written, so stop the container
first:

```sh
cd apps/host-selfhost
docker compose stop
docker run --rm -v host-selfhost_executor-data:/data -v "$PWD":/backup \
  busybox tar czf /backup/executor-data-$(date +%F).tgz -C /data .
docker compose start
```

The volume also holds the generated session secret and encryption keys, so
treat backups as secrets.
