# docker-glider

for replace my HAProxy service, available docker image, only support format ss[-obfs] maybe not compatible with your provider, mostly it works.

## Environment Vars

- VERBOSE `default:` True
- STRATEGY `default:` rr

> Optional: `rr`,`ha`, `lha`, `dh`

- ENV LISTEN `default:` :8443

> instance listen protocol, host network mode avoid udp block

- CHECK `default:` "www.msftconnecttest.com/connecttest.txt#expect=200"

>health check address

- SUBLINK `default:` ""

>SIP002 subscribe link

- TYPE `default:` ss

>Optional: `ss`, `obfs`

- COUNTRY `default:` "".

>filter subscribe link for forward.

- MANUAL `default:` 0

>set 1 to active `MANUAL_LINK`

- MANUAL_LINK `default:` ""

>like `tls://host:port[?skipVerify=true],ws://[@/path[?host=HOST]],vmess://[security:]uuid@?alterID=num`

- MANUAL_LINK_BAK  `default:` ""

>active while set `MANUAL_LINK`, same format.

## Example

## 1. Link

```yaml docker-compose.yml
version: "3.7"

x-env-common: &env-common
  environment:
    - &dh STRATEGY=dh
    - &sublink1 SUBLINK=https://somesip002linkaddress
    - &obfs TYPE=obfs
    - &area1 COUNTRY=someCountry

x-volume-common: &volume-common
  volumes:
    - &vsublink1 '/root/glider/sublink1:/tmp/sub'

x-glider-common: &glider-common
  image: dogbutcat/docker-glider
  restart: unless-stopped

services:

  name_it_please:
    <<: *glider-common
    ports:
      - "8443:8443"
      - "8443:8443/udp"
    volumes:
      - *vsublink1
    environment:
      - *sublink1
      - *area1

```

### 2. Manual

```yaml docker-compose.yml
version: "3.7"

x-env-common: &env-common
  environment:
    - &dh STRATEGY=dh
    - &lha STRATEGY=lha
    - &manual MANUAL=1
    - &manualink MANUAL_LINK_BAK=socks5://somemanuallinksetting
    - &manualinkbak MANUAL_LINK_BAK=socks5://somemanualbackuplink

x-glider-common: &glider-common
  image: dogbutcat/docker-glider
  restart: unless-stopped

services:
      
  manual_gcv:
    <<: *glider-common
    ports:
      - "8444:8443"
      - "8444:8443/udp"
    environment:
      - *manual
      - *lha
      - *manualink
      - *manualinkbak
```
