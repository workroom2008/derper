# 自用 DERP 中继服务器

Tailscale `derper` 服务的精简 Docker 构建版本，主要改动：
- 禁用 TLS 证书验证，方便使用自签名证书

由于禁用了证书验证，请仅在可控的内网环境中使用。

## 快速开始

> 一键部署到 Sealos：
>
> [![](https://sealos.io/Deploy-on-Sealos.svg)](https://sealos.io/products/app-store/derper)

容器使用合理的默认配置，当 `DERP_CERT_MODE=manual`（默认）且无证书时，会自动生成 2 年有效期的自签名证书。

### 自签名证书启动

```bash
docker run -d \
  --name derper \
  -p 12345:12345/tcp -p 3478:3478/udp \
  -e DERP_DOMAIN=derp.example.com \
  -e DERP_ADDR=':12345' \
  -e DERP_STUN_PORT='3478' \
  -e DERP_HTTP_PORT='-1' \
  -e DERP_VERIFY_CLIENTS="false" \
  -e DERP_CERT_DIR=/cert \
  -v $(pwd)/cert:/cert \
  ghcr.io/workroom2008/derper:latest
```

- 端口：`443/tcp` 用于 DERP，`3478/udp` 用于 STUN（设置 `DERP_STUN=false` 可禁用）。
- 证书：启动脚本会在 `certs/` 下生成 `{DERP_DOMAIN}.crt` 和 `.key`，可替换为自己的证书。

### Docker Compose

```yaml
services:
  derper:
    image: ghcr.io/workroom2008/derper:latest
    container_name: derper
    ports:
      - "12345:12345/tcp"
      - "3478:3478/udp"
    environment:
      DERP_DOMAIN: derp.example.com
      DERP_CERT_MODE: manual
      DERP_CERT_DIR: /cert
      DERP_ADDR: ':12345'
      DERP_STUN_PORT: '3478'
      DERP_HTTP_PORT: '-1'
      DERP_VERIFY_CLIENTS: "false"
    volumes:
      - ./cert:/cert
```

## 配置说明

环境变量及默认值：

- `DERP_DOMAIN`（无默认值）：DERP 服务器域名，需与客户端配置一致。
- `DERP_CERT_DIR`（`/app/certs`）：证书目录，存放 `*.crt` 和 `*.key` 文件。
- `DERP_CERT_MODE`（`manual`）：从 `DERP_CERT_DIR` 读取证书，缺失时自动生成自签名证书。
- `DERP_ADDR`（`:443`）：DERP 监听地址，示例中使用 `:12345` 需配合 `-p 12345:12345/tcp`。
- `DERP_STUN`（`true`）/ `DERP_STUN_PORT`（`3478`）：STUN 开关及端口。
- `DERP_HTTP_PORT`（`-1`）：HTTP 调试端口，默认关闭。
- `DERP_VERIFY_CLIENTS`（`true`/`false`）：是否验证 DERP 客户端。
- `DERP_VERIFY_CLIENT_URL`（空）：可选的客户端验证 URL。

## 注意事项

- 本构建禁用了 TLS 证书验证，请仅在可信网络中使用。
- `DERP_DOMAIN` 需与 Tailscale 节点配置的域名保持一致。

## 常见问题

### DERP 配置（Headscale/Tailscale）

使用自托管 DERP 服务器时，需在客户端配置中添加服务器信息。

- **Headscale：** 通过 `derp.json` 文件配置 DERP 节点。
- **Tailscale：** 在 [ACL 策略](https://tailscale.com/kb/1192/acl-derp-servers) 的 `derpMap` 中添加。

如果 DERP 使用自签名证书，Headscale 的 `derp.json` 需设置 `"InsecureForTests": true`。

**Headscale 配置示例 `derp.json`：**
```json
{
  "Regions": {
    "901": {
      "RegionID": 901,
      "RegionCode": "derp-cd",
      "RegionName": "derp-chengdu",
      "Nodes": [
        {
          "Name": "901a",
          "RegionID": 901,
          "DERPPort": xxxx,
          "STUNPort": xxxx,
          "STUNOnly": false,
          "HostName": "xxxx",
          "InsecureForTests": true
        }
      ]
    }
  }
}
```

### 常见错误

#### `not connected to home DERP region...`

**现象：**
```shell
# Health check:
#     - not connected to home DERP region 902
```

**原因：** 客户端配置了自签名证书的 DERP 服务器，但因不信任该证书导致连接失败。

**解决：** 在 Headscale 的 `derp.json` 中为该节点设置 `"InsecureForTests": true`，跳过 TLS 证书验证。

#### `TLS connection error... certificate is self-signed`

**现象：**
```shell
# Health check:
#     - TLS connection error for "": certificate is self-signed
```

**原因：** 客户端检测到 DERP 证书是自签名的，不受公共 CA 信任。

**解决：** 在自托管环境中此警告属正常现象，可安全忽略，不影响 DERP 服务功能。

#### `Tailscale could not connect to the 'test' relay server...`

**现象：**
```shell
# Health check:
#     - Tailscale could not connect to the 'test' relay server. Your Internet connection might be down, or the server might be temporarily unavailable.
```

**原因：** 客户端无法连接 DERP 端口，通常是网络连通性问题。

**解决：**
- 检查防火墙规则，确保 DERP 端口（`443/tcp` 和 `3478/udp`）未被拦截。
- 若 DERP 在 NAT 后，确认路由器已正确配置端口转发。
- 确认 `derper` Docker 容器正在运行且未崩溃。
