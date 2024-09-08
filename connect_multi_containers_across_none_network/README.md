# Manually connect multiple none-network containers | netns, veth, bridge, iproute2, k8s networking
[Youtube Video Link](https://youtu.be/pcJuFVNpdOg)

## Description
```
This video is a continuation of my previous tutorial, where I showed how to manually connect two Docker containers using iproute2 and virtual Ethernet pairs. In this follow-up, I expand on that setup by connecting multiple containers running in the none network. You’ll learn how to create virtual Ethernet pairs (veth), set up bridges, and configure routing tables between multiple containers, similar to Kubernetes (K8s) networking.

Key Concepts:
- Manually connecting multiple Docker containers using custom networks.
- Using iproute2 to create and configure network interfaces (veth).
- Setting up bridges on the host machine and linking container interfaces to them.
- Manually configuring IP addresses and routing for inter-container communication.
- Understanding how Kubernetes assigns IP addresses to pods, why it creates "pause" pods, and why the IP count is double the max_pods_per_node.

This video deepens your understanding of low-level container networking and provides insights into how Kubernetes handles pod networking. If you're looking to go beyond Docker's built-in networks and want full control over your container setup, this tutorial is perfect for you.

Commands covered:
- ip link add
- ip link set
- nsenter
- Setting up bridges and routing rules
- Testing connectivity with ping

Watch this video to explore advanced networking topics, including the rationale behind Kubernetes' networking architecture. Be sure to check out my previous video if you missed the foundation!

Previous Video: Manually Connecting Docker Containers with None Network https://youtu.be/XYudztmNvko

#docker #networking #kubernetes #dockernetworking #manual #manualnetworking #customnetworking #custom #veth #bridge #iproute2 #networkbridge #containercommunication #k8snetworking #tutorial #virtualethernet #podnetworking #advancednetworking #pausepod
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
# ./connect # use this to automatically create everything and skip everything ahead

pid1=$(docker inspect -f '{{.State.Pid}}' none-network-multi-connect-container1-1)
pid2=$(docker inspect -f '{{.State.Pid}}' none-network-multi-connect-container2-1)
pid3=$(docker inspect -f '{{.State.Pid}}' none-network-multi-connect-container3-1)
echo $pid1 $pid2 $pid3

# create virtual ethernet
ip link add container1_veth type veth peer name veth1_peer
ip link add container2_veth type veth peer name veth2_peer
ip link add container3_veth type veth peer name veth3_peer

# move each end of ethernets to containers
ip link set veth1_peer netns $pid1
ip link set veth2_peer netns $pid2
ip link set veth3_peer netns $pid3

# add address to links
nsenter --net=/proc/$pid1/ns/net ip addr add 192.168.1.1/24 dev veth1_peer
nsenter --net=/proc/$pid2/ns/net ip addr add 192.168.1.2/24 dev veth2_peer
nsenter --net=/proc/$pid3/ns/net ip addr add 192.168.1.3/24 dev veth3_peer

# container's link up
nsenter --net=/proc/$pid1/ns/net ip link set veth1_peer up
nsenter --net=/proc/$pid2/ns/net ip link set veth2_peer up
nsenter --net=/proc/$pid3/ns/net ip link set veth3_peer up

# create bridge
ip link add container_br type bridge

# assign other end of virtual ethernet to bridge
ip link set container1_veth master container_br
ip link set container2_veth master container_br
ip link set container3_veth master container_br

# link up
ip link set container1_veth up
ip link set container2_veth up
ip link set container3_veth up
ip link set container_br up

# ping test
docker exec none-network-multi-connect-container2-1 ping -c1 192.168.1.1
docker exec none-network-multi-connect-container2-1 ping -c1 192.168.1.3
docker exec none-network-multi-connect-container3-1 ping -c1 192.168.1.1
```

