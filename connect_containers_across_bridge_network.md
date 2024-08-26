# Connect Docker Containers Across Bridge Networks | iproute2
[Youtube Video Link](https://www.youtube.com/watch?v=VjYf544VFqA&list=PLJToDA8ph9VXodmGmNBYM6GWra3Yv_s44)

## Description
```
In this video, I demonstrate how to connect Docker containers running inside a docker environment, even when they are in different bridge networks. Using iproute2, we establish routes for seamless communication, and tools like tcpdump and ping are employed for thorough network debugging and analysis. This tutorial is ideal for anyone working with Docker in Docker (dind) environments and dealing with complex container networking challenges.

Key topics covered:
- Using docker to run containers
- Adding routes between different bridge networks with iproute2
- Debugging with tcpdump and ping
- Step-by-step tutorial for cross-network container communication

Great for Docker developers of all levels!

#dockercontainer #docker #container #linux #linuxnetwork #networking #tmux #iproute2 #ip #ping #learningvideos #learning #handsonlearning #tutorial #bridge #bridgenetworking #router #iproute #dind
```

## Tutorial
### Create Docker IN Docker (dind) container
```bash
sudo docker network create test
sudo docker run --rm --net test --name test --privileged docker:dind
sudo docker exec -it test sh
```

Now we are going to use this container

### Create two bridge network(isolated)
```bash
docker network create net0
docker network create net1
```

### Create Router and containers
- Router is in both network, while containers are in single network
- We will use ubuntu image and install all dependencies manually

Networks:
- net0:
  - subnet: 172.19.0.0/16
  - default gatway: 172.19.0.1
- net1:
  - subnet: 172.20.0.0/16
  - default gatway: 172.20.0.1

Containers:
- Router: net0(172.19.0.2), net1(172.20.0.2)
- Container0: net0(172.19.0.3)
- Container1: net1(172.20.0.3)
 
```bash
docker run -d --name router --net net0 --net net1 --cap-add=NET_ADMIN --entrypoint=sleep ubuntu infinity
docker run -d --name container0 --net net0 --cap-add=NET_ADMIN --entrypoint=sleep ubuntu infinity
docker run -d --name container1 --net net1 --cap-add=NET_ADMIN --entrypoint=sleep ubuntu infinity
```

#### Setup containers and router
Exec to each containers and install require packages
```bash
apt update && apt install -y iproute2 iputils-ping tcpdump
```

### Establishing connectivity between containers via router
- Container0 can communicate router(172.19.0.2)
- Container1 can communicate router(172.20.0.2)

When container0 wants to conect 172.20.0.2(router) then the packet will go to default gateway(172.19.0.1), which doesn't know about (172.20.0.0/16) subnet
similarly when container1 wants to conect 172.19.0.2(router) then the packet will go to default gateway(172.20.0.1), which doesn't know about (172.19.0.0/16) subnet

For establishing communcation we need to router these packet via router, for that we need to add route using iproute2, since router already know how to forward packet, packet will reach to the desired destination

```bash
# on container0
ip route add 172.20.0.0/16 dev eth0 via 172.19.0.2

# on container1
ip route add 172.19.0.0/16 dev eth0 via 172.20.0.2
```

