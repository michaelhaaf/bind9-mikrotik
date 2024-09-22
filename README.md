# Bind9 + DHCP for Mikrotik Container

Approach inspired by, and some instructions adapted directly from, https://github.com/Fluent-networks/tailscale-mikrotik.

## Goal

This example runs bind9 as a local LAN-only DNS/DHCP server. This server maintains working forward and reverse DNS searches for all static and dynamic hosts on specified subnets in a LAN.

The configuration presented in this docker repository is inspired by the techniques shown in [this great DNS/DHCP tutorial published on arstechnica](https://arstechnica.com/information-technology/2024/02/doing-dns-and-dhcp-for-your-lan-the-old-way-the-way-that-works/).

## Instructions

Storage of the docker image on the router uses a USB drive mounted as **usb1** due to the limited storage (128MB) available on the router. To configure storage devices see the [Mikrotik Disks guide](https://help.mikrotik.com/docs/display/ROS/Disks).

### Configure the Router for Containers

1. Enable container mode, and reboot.

If you have not yet created a container on your Mikrotik device, this step is required. Otherwise you can skip it.

```
/system/device-mode/update container=yes
```

2. Create a bridge for your Mikrotik containers

If you have not yet created a bridge for your containers on your Mikrotik device, this step is required. Otherwise you can skip it.

```
/interface/bridge add name=containers
/ip/address add address=172.17.0.1/24 interface=containers
```

3. Create a veth interface for the container.

```
/interface/veth add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
```

Each container on your Mikrotik device needs its own virtual ethernet interface. Here we use the `172.17.0/24` subnet, but subnet choice is up to you.

In my case, since I already have Mikrotik containers, I need to use a different address and veth name. The important part is that the `veth` and the `address` are unique to each container.

4. Add `vethN` as a port to that bridge.

```
/interface/bridge/port add bridge=containers interface=veth1
```

5. Create configuration mounts

While much of the configuration for this image comes with the image (see the `files` directory), there are directories used by `bind9` that we cannot set in advance: `/var/bind/cache`. In order for these files to be persisted on container restart/recreation, we need to mount them elsewhere on the mikrotik external drive:

```
/container mounts add name="var_bind9" src="/usb1/var-bind" dst="/var/cache/bind"
```

6. Create the container

The container can be created either (a) via a `.tar` archive or (b) via the ghcr.io container registry.

a. Build locally to `.tar`, create container

Build the image from the root of this repository. Create the tar and transfer it to your mikrotik:

```
docker buildx build --no-cache --platform arm64 --output=type=docker -t bind9 .
docker save bind9 > bind9.tar
scp bind9.tar user@ip-address:/usb1/images
```


b. Configure the registry URL and add the container.

```
/container/config 
set registry-url=https://ghcr.io tmpdir=usb1/pull
```

Then, add the container via either method:

```
/container add file=usb1/images/bind9.tar interface=veth1 root-dir=usb1/bind9 start-on-boot=yes hostname=bind9 
/container add remote-image=michaelhaaf/bind9-mikrotik:main interface=veth1 root-dir=usb1/bind9 start-on-boot=yes hostname=bind9 mounts=etc_bind9,var_bind9
```
If you want to see the container output in the router log add `logging=yes` to the container add command.


### Start the Container

Ensure the container has been extracted and added by verifying `status=stopped` using `/container/print` 

Start the container. If you have more than one, `0` might be the wrong argument.

```
/container/start 0
```

### Verifying the container works

First, run `ps` to double check that everything worked:

```
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 {entrypoint.sh} /bin/sh /usr/local/bin/entrypoint.sh
    6 named     0:00 named -c /etc/bind/named.conf -g -u named
   16 root      0:00 ps
```

You may instead see the following:

```
/ # ps
PID   USER     TIME  COMMAND
    1 root      0:00 {entrypoint.sh} /bin/sh /usr/local/bin/entrypoint.sh
   12 root      0:00 tail -f /dev/null
   13 root      0:00 ps
```

`tail -f /dev/null` is a dummy continuous command that activates if `named` fails. This allows us to debug the container without it immediately completing its process and stopping.

Go ahead and try the `named-c /etc/bind/named.conf -g -u named` command to see what errors are stopping `named` from working.

### Verifying DNS

```
dig @localhost bind9.michaelhaaf.internal +short
dig @localhost -x 172.17.0.4 +short
```

You should see an IP address and a hostname respectively.

### Verifying DHCP

```
dhcpd -t
```

If everything is OK, the command will exit with status 0 and some generic informational message. If there's something wrong, it will throw a status other than 0, and you can consult `/var/log/syslog | grep -i dhcpd` to see what's wrong.
