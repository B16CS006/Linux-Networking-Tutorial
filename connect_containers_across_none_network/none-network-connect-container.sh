#! /bin/sh

export PROJECT="none-network-connect"
export PROJECT_VERSION=1
export SLEEP_TIME=1

export CONTAINERS="container1 container2"

export CIDR=24

container1_ip="192.168.10.1"
container1_pid=""

container2_ip="192.168.10.2"
container2_pid=""

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

echo "PID: container1($container1_pid), container2($container2_pid)"

echo -n "updating iproute2 package... "
apk update 1>/dev/null 2>&1 && apk add iproute2 1>/dev/null 2>&1
echo " done"

set -e

# create virtual ethernet
echo -n "Creating virtual Ethernet..."; sleep "$SLEEP_TIME"
ip link add veth1 type veth peer name veth2
echo " done"

echo "===================== container1 setup ====================="
echo -n "Moving veth1 to container1..."; sleep "$SLEEP_TIME"
ip link set veth1 netns $container1_pid
echo " done"

echo -n "Add address to container1(veth1)..."; sleep "$SLEEP_TIME"
docker exec "$PROJECT-container1-$PROJECT_VERSION" ip addr add "$container1_ip/$CIDR" dev veth1
echo " done"

echo -n "Link up container1(veth1)..."; sleep "$SLEEP_TIME"
docker exec "$PROJECT-container1-$PROJECT_VERSION" ip link set veth1 up
echo " done"


echo "===================== container2 setup ====================="
echo -n "Moving veth2 to container2..."; sleep "$SLEEP_TIME"
ip link set veth2 netns $container2_pid
echo " done"

echo -n "Add address to container1(veth1)..."; sleep "$SLEEP_TIME"
nsenter --net=/proc/$container2_pid/ns/net ip addr add "$container2_ip/$CIDR" dev veth2
echo " done"

echo -n "Link up container2(veth2)..."; sleep "$SLEEP_TIME"
nsenter --net=/proc/$container2_pid/ns/net ip link set veth2 up
echo " done"

echo "===================== PING TEST ====================="
echo "FROM container1 to container2"
docker exec "$PROJECT-container1-$PROJECT_VERSION" ping -c1 "$container2_ip"

## ping is not installed on container2
# echo "FROM container2 to container1"
# docker exec "$PROJECT-container2-$PROJECT_VERSION" ping -c1 "$container1_ip"

echo "--------------------- Thanks -------------------------"
