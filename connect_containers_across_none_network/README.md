# Manual Container Networking: Connect Containers Across None Network | iproute2, netns, dind
[Youtube Video Link](https://youtu.be/XYudztmNvko)

## Description
```
In this video, I demonstrate how to manually connect two Docker containers running with network=none using iproute2 and virtual Ethernet pairs. By following this method, you will learn how to create network namespaces, add veth pairs, and assign IP addresses to establish communication between containers. Perfect for anyone who prefers to avoid Docker's built-in networking features and is interested in understanding low-level network configuration.

Commands covered:
- ip link add
- ip link set
- nsenter
- Assigning IP addresses and bringing interfaces up
- Testing connectivity with ping

Whether you're working with custom Docker networking or want more control over your container connections, this tutorial provides a step-by-step guide. Subscribe for more Docker and networking tutorials!

#docker #networking #linuxnetwork #dockernetworking #dockernonenetwork #nonenetwork #iproute #iproute2 #veth #virtualethernet #ethernet #containerconversion #connect #connection #communication #manual #nsenter #link #address #ipaddress #dind #tutorial #handsonlearning #ping #namespace #netns #networknamespace
```

## Tutorial
### Create Docker IN Docker (dind) container

Now we are going to use this container

### Create containers
- We will use ubuntu image and install all dependencies manually

```bash
docker compose up -d
```

#### Setup containers
Run following in dind container
```
# existing package doesn't has netns
apk update && apk add iproute2

cd /data/tutorial/networking/none-network
docker compose up -d

pid1=$(docker inspect -f '{{.State.Pid}}' net-scratch-container1-1)
pid2=$(docker inspect -f '{{.State.Pid}}' net-scratch-container2-1)
echo $pid1 $pid2

# create virtual ethernet
ip link add veth1 type veth peer veth2

# move each end of ethernet to containers
ip link set veth1 netns $pid1
ip link set veth2 netns $pid2

# add address and link up
nsenter --net=/proc/$pid1/ns/net ip link set veth1 up
nsenter --net=/proc/$pid1/ns/net ip addr add 192.168.1.1/24 dev veth1

nsenter --net=/proc/$pid2/ns/net ip link set veth2 up
nsenter --net=/proc/$pid2/ns/net ip addr add 192.168.1.2/24 dev veth2

# ping test
docker exec net-scratch-container1-1 ping 192.168.1.2
docker exec net-scratch-container2-1 ping 192.168.1.1
```

