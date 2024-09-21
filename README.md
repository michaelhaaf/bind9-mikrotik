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

2. Create a veth interface for the container.

```
/interface/veth add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
```

Each container on your Mikrotik device needs its own virtual ethernet interface. Here we use the `172.17.0/24` subnet, but this is up to you.

In my case, since I already have Mikrotik containers, I need to use a different address and veth name. The important part is that the `veth` and the `address` are unique to each container.

3. Create a bridge for your Mikrotik containers

```
/interface/bridge add name=containers
/ip/address add address=172.17.0.1/24 interface=containers
```

4. Add `vethN` as a port to that bridge.

```
/interface/bridge/port add bridge=containers interface=veth1
```

5. Define mounts for the container as per below.

Define the mounts as per below.

```
/container mounts add name="etc_dns" src="/usb1/etc/bind" dst="/etc/bind"
/container mounts add name="var_dns" src="/usb1/var/lib/bind" dst="/var/lib/bind"
```

6. Create the container

The container can be created via the ghcr.io container registry.

Configure the registry URL and add the container.

```
/container/config 
set registry-url=https://ghcr.io tmpdir=usb1/pull

/container add remote-image=michaelhaaf/bind9-mikrotik:main interface=veth1 envlist=dns root-dir=usb1/dns mounts=dns start-on-boot=yes hostname=dns dns=8.8.4.4,8.8.8.8
```

### Start the Container

Ensure the container has been extracted and added by verifying `status=stopped` using `/container/print` 

Start the container. If you have more than one, `0` might be the wrong argument.

```
/container/start 0
```

### Verifying DNS

More to come

### Verifying DHCP

More to come
