# MaruMesh

MaruMesh is a cross-platform mesh agent and control plane that registers devices through SSO and brings up secure channels with a userspace WireGuard tunnel over ICE paths.

## Core Features

- `marumesh up|down` handles login, token storage, secure channel startup, and shutdown.
- `marumesh up` connects to the default control plane, `https://marumesh.lab.highmaru.com`.
- If no login token exists, `marumesh up` prints an SSO login URL.
- If a login token exists, `marumesh up` uses it to authenticate with the control plane, starts the secure channel in the background, and returns.
- On Windows, `up` passes the same config path to the service command after login and starts the Windows Service.
- WireGuard is provided through Go userspace dependencies; external `wg` or `ip` CLI packages are not required.
- The server executable embeds the React dashboard, so no separate static asset copy is required.
- The dashboard checks the SSO session on startup and shows only the login screen before authentication.
- Regular users can view their own or shared devices, see device names and last login time, and rename or delete their own devices. Superusers can see all user devices and manage device names, device deletion, global policies, and users.

## Build

```bash
make build
```

The CLI and server binaries for the current platform are created under:

```text
bin/<os>-<arch>/marumesh
bin/<os>-<arch>/marumesh-server
```

Build all distribution targets:

```bash
make build-all
make release-assets
```

The Windows server binary is created at `bin/windows-amd64/marumesh-server.exe`. `make release-assets` creates GitHub Release upload files under `dist/`. macOS builds must be produced natively because of the systray dependency. Intel Macs use `darwin-amd64`; Apple Silicon Macs (M1/M2/M3/M4) use `darwin-arm64`.

## Verify

```bash
make test
```

`make test` rebuilds the React frontend dist into the server embed path and then runs Go tests.

## Run the Control Plane

### Docker Compose

Copy `.env.example` to `.env`, then fill in values for the Docker PostgreSQL container named `postgresql`. The PostgreSQL container must be attached to the same Docker network, `backend_default`.

```bash
cp .env.example .env
docker network connect backend_default postgresql
docker compose up --build
```

Dashboard:

```text
http://localhost:8000
```

Docker Compose passes `.env` to the container with `env_file`. `HOST_PORT` is the host port, and `PORT` is the container server port. The default mapping is `8000:8080`.

### Single Server Executable

```bash
./bin/linux-amd64/marumesh-server
```

The server binary embeds the React dashboard. If `STATIC_PATH` is set, that external static directory is served first. Otherwise, the embedded frontend is used.

Linux systemd install script:

```bash
./install-server.sh
```

`install-server.sh` copies only the server binary and does not copy separate static assets.

## Agent/CLI Usage

Client install URL:

```bash
curl -fsSL https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.sh | sh
marumesh up
```

Windows client install URL:

```powershell
iwr https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.ps1 -UseB | iex
marumesh up
```

The public install scripts download client binaries from the public distribution repository GitHub Releases: `https://github.com/dirmich/maru-mesh/releases/latest/download`. Release assets must be named `marumesh-linux-amd64`, `marumesh-linux-arm64`, `marumesh-darwin-amd64`, `marumesh-darwin-arm64`, and `marumesh-windows-amd64.exe`.

Linux:

```bash
sudo install -m 0755 ./bin/linux-amd64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

macOS Intel:

```bash
sudo install -m 0755 ./bin/darwin-amd64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

macOS Apple Silicon (M1/M2/M3/M4):

```bash
sudo install -m 0755 ./bin/darwin-arm64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

Install or remove the OS service:

```bash
sudo marumesh install-service
sudo marumesh uninstall-service
```

Windows:

```powershell
C:\MaruMesh\marumesh.exe up
C:\MaruMesh\marumesh.exe down
C:\MaruMesh\marumesh.exe uninstall-service
```

On Windows, `up` passes the config path that contains the login token to the service command.
Use `--control https://mesh.example.com` only when connecting to a different control plane.
`marumesh up` starts the secure channel in the background and returns. Use `marumesh run` only when you want a foreground daemon process, or `marumesh up --debug` when you need detailed foreground diagnostics.
In `tun` mode, the virtual interface is configured with the assigned virtual IP before `up` returns. On macOS the interface appears as `utunN` in `ifconfig`.
The default virtual IP allocation range is `100.64.0.0/24`. Operators can change it with `MARUMESH_VIRTUAL_CIDR` on the control plane when it overlaps an existing network.
MaruMesh includes MagicDNS for the `.maru` zone and a hosts fallback for short names. Peer names are published locally as `dev`, `dev.maru`, and `<device-id>.maru` when the agent has OS resolver or hosts permissions.
On macOS, `marumesh up` shows the menubar tray by default. Use `--headless` to run without the tray. Linux defaults to headless mode. Windows uses a tray menu when the desktop service/session supports it.

Create a local TCP proxy to a remote device service:

```bash
marumesh connect <device-id> --remote-port 22
```

## SSO and Dashboard

Real SSO requires these server environment variables:

```env
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
AUTH_CALLBACK_URL=http://localhost:8000/api/v1/auth/callback
JWT_SECRET=...
```

`JWT_SECRET` is required in production. For local development only, `MARUMESH_DEV_INSECURE_JWT=true` enables the temporary development fallback.

## Project Structure

- `src/cmd/marumesh`: unified CLI and agent executable
- `src/cmd/marumesh-server`: control plane server and embedded dashboard
- `src/internal`: internal agent, tunnel, policy, and network implementation
- `frontend`: React dashboard source
- `docs`: PRD, install guides, and feature docs

For command details, see [docs/commands.md](docs/commands.md). For deployment details, see [docs/install_guide.md](docs/install_guide.md) and [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md).
