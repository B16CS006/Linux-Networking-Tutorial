#! /bin/sh

export PROJECT="none-network-multi-connect"
export PROJECT_VERSION=1
export SLEEP_TIME=0

export CONTAINERS="container1 container2 container3"

export CIDR=24
export CONTAINER_VETH_NAME=eth1
export CONTAINER_BRIDGE_NAME=container_br
export CONTAINER_BRIDGE_IP="192.168.11.0"

container1_ip="192.168.11.1"
container1_pid=""

container2_ip="192.168.11.2"
container2_pid=""

container3_ip="192.168.11.3"
container3_pid=""

# check if containers are running
for container in $CONTAINERS; do
	container_name="$PROJECT-$container-$PROJECT_VERSION"
	echo -n "checking running status of $container_name: "
	container_status=$(docker inspect --format '{{.State.Status}}' "$container_name"  2>/dev/null)

	if [ "$container_status" != "running" ]; then
		echo "not running"
		exit 1;
	fi
	echo -n "running";
	_pid=$(docker inspect --format '{{.State.Pid}}' "$container_name")
	if [ $_pid -gt 0 ]; then
		echo
		eval "${container}_pid=$_pid"
	else
		echo ", Invalid PID: $_pid"
		exit 1
	fi
done

echo "PID: container1($container1_pid), container2($container2_pid), container3($container3_pid)"

echo "PLEASE UPDATE IPROUTE2 IF THINGS FAILS"
# echo -n "updating iproute2 package... "
# apk update 1>/dev/null 2>&1 && apk add iproute2 1>/dev/null 2>&1
# echo " done"

set -e

for container in $CONTAINERS; do
	echo "================================== container: $container =================================="
	container_pid=$(eval  echo "\${${container}_pid}")
	container_ip=$(eval  echo "\${${container}_ip}")

	echo -n "Creating virtual Ethernet..."; sleep "$SLEEP_TIME"
	ip link add "${container}_veth" type veth peer name "${CONTAINER_VETH_NAME}"
	echo " done"

	echo -n "Connect one end of the ethernet cable(${CONTAINER_VETH_NAME}) to container and keep other on host for bridge..."; sleep "$SLEEP_TIME"
	echo test
	ip link set "${CONTAINER_VETH_NAME}" netns "${container_pid}"
	echo " done"

	echo -n "Add address to ${CONTAINER_VETH_NAME}..."; sleep "$SLEEP_TIME"
	nsenter --net=/proc/${container_pid}/ns/net ip addr add "${container_ip}/$CIDR" dev "${CONTAINER_VETH_NAME}"
	echo " done"

	echo -n "Set link up for lo, ${CONTAINER_VETH_NAME} and ${container}_veth ..."; sleep "$SLEEP_TIME"
	nsenter --net="/proc/${container_pid}/ns/net" ip link set lo up
	nsenter --net="/proc/${container_pid}/ns/net" ip link set "${CONTAINER_VETH_NAME}" up
	ip link set "${container}_veth" up
	echo " done"
	echo
done
echo "======================== connecting virtual ethernet cables together ======================"


echo -n "Create a network bridge..."
ip link add "${CONTAINER_BRIDGE_NAME}" type bridge
echo " done"

echo -n "Add address to bridge interface(on host machine)..."
ip addr add "${CONTAINER_BRIDGE_IP}/$CIDR" dev "${CONTAINER_BRIDGE_NAME}"
echo " done"

echo -n "Set bridge link up..."
ip link set "${CONTAINER_BRIDGE_NAME}" up
echo " done"

echo -n "Assign container virtual ethernet to the bridge and update conatiner routing table..."
for container in $CONTAINERS; do
	container_pid=$(eval  echo "\${${container}_pid}")
	container_ip=$(eval  echo "\${${container}_ip}")

	ip link set "${container}_veth" master "${CONTAINER_BRIDGE_NAME}"
	nsenter --net="/proc/${container_pid}/ns/net" ip route add default via "${CONTAINER_BRIDGE_IP}"
done
echo " done"

echo "===================== PING TEST ====================="
echo "FROM container2 to container3"
docker exec "$PROJECT-container2-$PROJECT_VERSION" ping -c1 "$container3_ip"

echo "FROM container3 to container1"
docker exec "$PROJECT-container3-$PROJECT_VERSION" ping -c1 "$container1_ip"

echo "FROM container3 to container2"
docker exec "$PROJECT-container3-$PROJECT_VERSION" ping -c1 "$container2_ip"

echo "--------------------- Thanks -------------------------"
