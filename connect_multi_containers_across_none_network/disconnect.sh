#! /bin/sh

export PROJECT="none-network-multi-connect"
export PROJECT_VERSION=1
export SLEEP_TIME=0

export CONTAINERS="container1 container2 container3"

export CIDR=32
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

for container in $CONTAINERS; do
	container_pid=$(eval  echo "\${${container}_pid}")
	container_ip=$(eval  echo "\${${container}_ip}")

	echo -n "Deleting virtual Ethernet(${container}_veth)..."; sleep "$SLEEP_TIME"
	ip link del "${container}_veth" type veth
	echo " done"
	echo
done

echo -n "Deleting the network bridge(${CONTAINER_BRIDGE_NAME})..."
ip link del "${CONTAINER_BRIDGE_NAME}" type bridge
echo " done"

echo "--------------------- Thanks -------------------------"
