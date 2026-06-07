# MaruMesh PRD
Secure Cross-Platform Agent & Overlay Connectivity Platform

---

# 1. Overview

## Product Name
**MaruMesh**

## One-Line Description
A lightweight cross-platform agent and control platform that enables devices, servers, and applications to securely connect through an automatically configured encrypted network using SSO authentication.

## Core Idea
Install an agent → login with SSO → device automatically joins secure network → applications use local API to communicate with remote devices safely.

The system is designed as a **reusable connectivity platform** for multiple projects including:

- Marubot
- Server management tools
- IoT gateways
- Camera systems
- Robotics platforms
- Internal developer tools

---

# 2. Goals

Provide a secure infrastructure that solves common connectivity and management problems.

### Primary Goals

1. **Install → Login → Connect**
   - Device should join the network within minutes.

2. **Application simplicity**
   - Applications do not implement networking logic.

3. **Secure identity**
   - Every device has a cryptographic identity.

4. **Reusable platform**
   - Multiple projects use the same connectivity layer.

5. **Minimal agent footprint**
   - Lightweight single binary agent.

---

# 3. Problems to Solve

Current infrastructure suffers from several problems:

- Devices behind NAT cannot be easily accessed.
- VPN setup is complex.
- Port forwarding is insecure.
- Applications must implement their own networking logic.
- Identity and encryption management becomes difficult at scale.

MaruMesh solves these problems by introducing:

- device identity
- encrypted overlay network
- SSO-based registration
- local agent API
- centralized policy

---

# 4. Core Architecture

The system consists of three primary layers.

```
Applications
      ↓
Local Agent API
      ↓
MaruMesh Agent
      ↓
Encrypted Overlay Network
      ↓
Control Plane
```

---

# 5. System Components

## 5.1 Control Plane

Central management system.

Responsibilities:

- SSO authentication
- organization management
- device registry
- policy distribution
- token issuing
- relay coordination
- audit logging

Components:

- Auth Service
- Device Registry
- Policy Engine
- Token Service
- Relay Directory
- Audit Service

---

## 5.2 Agent

Cross-platform runtime installed on every device.

Responsibilities:

- device identity management
- overlay network connection
- local API interface
- token broker
- policy enforcement
- health reporting

Supported platforms:

- Linux
- macOS
- Windows

Recommended implementation language:

```
Go
```

Binary goals:

```
single executable
< 20MB
minimal dependencies
```

---

## 5.3 SDK

Applications use SDKs instead of implementing networking.

Supported languages:

- JavaScript / TypeScript
- Python
- Go

SDK responsibilities:

- communicate with local agent
- open sessions
- request tokens
- proxy connections

---

# 6. Device Identity Model

Each device has a cryptographic identity.

Structure:

```
device_id
device_public_key
device_private_key
device_certificate
organization_id
```

Security properties:

- private key never leaves device
- server only stores public key
- device certificate issued by control plane

---

# 7. Authentication Flow

### Device Registration

```
1. install agent
2. run agent login
3. browser opens SSO login
4. user authenticates
5. server approves device
6. device certificate issued
7. policy downloaded
8. device joins network
```

---

# 8. Overlay Network

Agent automatically forms encrypted tunnels between peers.

Features:

- peer discovery
- NAT traversal
- encrypted communication
- relay fallback
- automatic reconnection

Connection priority:

```
1 direct P2P
2 relay fallback
```

---

# 9. Local Agent API

Applications communicate through the local agent.

Transport methods:

- Unix socket (Linux/macOS)
- Named pipe (Windows)
- localhost HTTP (optional)

### Example Endpoints

```
GET /v1/status
GET /v1/devices
POST /v1/session
POST /v1/token
POST /v1/proxy/http
POST /v1/proxy/tcp
```

---

# 10. Session Example

Request:

```
POST /v1/session

{
  "target": "robot-01",
  "protocol": "tcp",
  "port": 22
}
```

Response:

```
{
  "session_id": "...",
  "local_port": 54022
}
```

Application then connects to:

```
localhost:54022
```

---

# 11. Token System

API calls use **short-lived tokens**.

Structure:

```
issuer
device_id
user_id
target_service
expiration
signature
```

Token lifetime:

```
5–10 minutes
```

Properties:

- audience restricted
- device bound
- revocable

---

# 12. Policy System

Policies are defined centrally.

Example:

```
group:robot
group:camera
group:admin
```

Access rules example:

```
robot -> camera:read
admin -> robot:control
```

Policies are distributed to agents and cached locally.

---

# 13. Device Tagging

Devices can be labeled for management.

Examples:

```
tag:robot
tag:camera
tag:sensor
tag:gateway
```

Tags assist with:

- policy rules
- grouping
- monitoring

---

# 14. Remote Access Capabilities

Agent supports multiple remote connection types.

Supported:

- SSH proxy
- HTTP proxy
- TCP tunnel

Example:

```
agent proxy http camera-01:8080
```

---

# 15. Data Model

## Organization

```
id
name
plan
settings
```

## User

```
id
org_id
email
role
groups
```

## Device

```
id
org_id
user_id
hostname
device_public_key
ip
tags
os
version
last_seen
```

## Policy

```
id
org_id
policy_json
version
```

## Session

```
id
src_device
dst_device
protocol
start_time
end_time
```

---

# 16. Security Design

## Core Security Principles

1. Private keys never leave devices  
2. All communication is encrypted end-to-end  
3. Tokens are short-lived  
4. Policies enforced centrally  
5. Full audit logging  

---

## Secure Key Storage

### Linux

```
kernel keyring
secure file storage (0600)
```

### macOS

```
Keychain
```

### Windows

```
DPAPI
Credential Manager
```

---

# 17. Agent Architecture

Agent modules:

```
identity_manager
control_client
policy_engine
tunnel_manager
local_api_server
token_manager
health_reporter
auto_update_service
```

Responsibilities:

- maintain secure identity
- enforce policy
- maintain connections
- expose local API

---

# 18. Development Roadmap

## Phase 1 — MVP (8 weeks)

Features:

- agent runtime
- device registration
- SSO login
- local API
- device list
- TCP proxy

---

## Phase 2 — Access Control (6 weeks)

Features:

- policy engine
- group management
- token service
- audit logging

---

## Phase 3 — Networking (8 weeks)

Features:

- NAT traversal
- relay servers
- internal DNS
- multi-region support

---

## Phase 4 — Platform Expansion (8 weeks)

Features:

- SDK
- browser access
- service publishing
- developer tools

---

# 19. Engineering Rules

These rules ensure efficient development and maintainability.

---

## Rule 1 — Agent must remain generic

The agent must **never contain product-specific logic**.

Forbidden:

- robotics logic
- camera processing
- sensor handling

---

## Rule 2 — API stability

Breaking changes are not allowed.

Versioning structure:

```
/v1/
/v2/
```

---

## Rule 3 — Applications must not implement networking

All apps must use:

```
SDK
or
Agent Local API
```

---

## Rule 4 — No long-lived credentials

Forbidden:

```
long-lived API keys
group shared authentication keys
```

---

## Rule 5 — Offline tolerance

If the control plane fails:

```
existing peer connections continue
```

---

## Rule 6 — Centralized policy

Only the control plane may update policies.

Agents receive read-only copies.

---

## Rule 7 — Full auditability

Every action must be logged.

Required fields:

```
user
device
target
action
timestamp
```

---

## Rule 8 — Backward compatibility

Agent updates must maintain compatibility for at least:

```
6 months
```

---

## Rule 9 — Relay design

Relay servers must remain stateless.

Properties:

```
forward encrypted packets only
no decryption capability
```

---

## Rule 10 — Mutual authentication

All connections require:

```
device certificate
+
short-lived token
```

---

# 20. Success Metrics

Key metrics to measure system success:

```
agent install success rate
device online rate
direct connection ratio
relay usage percentage
session latency
```

---

# 21. MVP Success Criteria

Minimum viable system must allow:

```
install agent
SSO login
device registration
secure remote connection
```

Total setup time goal:

```
under 3 minutes
```

Applications must be able to control remote devices **using only the agent API**.

---

# Final Architecture Principle

```
Agent = security & connectivity kernel
Control Plane = identity & policy
SDK = application interface
Applications = feature layer
```

Example applications using MaruMesh:

```
Marubot
Camera Manager
Server Admin
IoT Gateway
```

All applications rely on the same **secure connectivity foundation**.
