#!/bin/bash
# Install Glances (https://github.com/nicolargo/glances)
#
# Requirements:
#
#    python 2.7,>=3.4
#    psutil>=5.3.0 (better with latest version)
#
# Optional dependencies:
#
#    bernhard (for the Riemann export module)
#    bottle (for Web server mode)
#    cassandra-driver (for the Cassandra export module)
#    couchdb (for the CouchDB export module)
#    docker (for the Docker monitoring support) [Linux/macOS-only]
#    elasticsearch (for the Elastic Search export module)
#    hddtemp (for HDD temperature monitoring support) [Linux-only]
#    influxdb (for the InfluxDB export module)
#    kafka-python (for the Kafka export module)
#    netifaces (for the IP plugin)
#    nvidia-ml-py3 (for the GPU plugin)
#    pika (for the RabbitMQ/ActiveMQ export module)
#    potsdb (for the OpenTSDB export module)
#    prometheus_client (for the Prometheus export module)
#    py-cpuinfo (for the Quicklook CPU info module)
#    pygal (for the graph export module)
#    pymdstat (for RAID support) [Linux-only]
#    pySMART.smartx (for HDD Smart support) [Linux-only]
#    pysnmp (for SNMP support)
#    pystache (for the action script feature)
#    pyzmq (for the ZeroMQ export module)
#    requests (for the Ports, Cloud plugins and RESTful export module)
#    scandir (for the Folders plugin) [Only for Python < 3.5]
#    statsd (for the StatsD export module)
#    wifi (for the wifi plugin) [Linux-only]
#    zeroconf (for the autodiscover mode)
#
# INSTALL_MODULES="action,browser,cloud,cpuinfo,chart,docker,export,folders,gpu,ip,raid,snmp,web,wifi"
#
INSTALL_MODULES=""

# Execute a command as root (or sudo)
function do_with_root()
{
    # already root? "Just do it" (tm).
    if [[ $(whoami) = 'root' ]]; then
        bash -c "$@"
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo bash -c "$@"
    else
        echo "This script must be run as root." >&2
        exit 1
    fi
}

# Check if a package is installed
function check_installed()
{
  pkg_name="$1"
  if [ -z "${pkg_name}" ]; then
    echo >&2 "ERROR: Package name not provided to check script."
    exit 1
  fi

  if hash apt-cache 2>/dev/null; then
    if apt-cache policy "${pkg_name}" | grep -v '(none)' | grep -q "Installed"; then
      return 0
    fi
  fi

  return 1
}

if ! check_installed "python-dev"; then
    echo "Installing python-dev..."
    if ! do_with_root apt-get install python-dev; then
        echo >&2 "ERROR: Failed to install python-dev package."
        exit 1
    fi
elif ! hash pip 2>/dev/null; then
    if ! check_installed "python-pip"; then
        echo "Installing python-pip..."
        if ! do_with_root apt-get install python-pip; then
            echo >&2 "ERROR: Failed to install python-pip package."
            exit 1
        fi
    fi
else
    echo "Found $(pip --version 2> /dev/null)"
fi

upgrade_str=""
if hash glances 2>/dev/null; then
    echo "Glances already installed; upgrading..."
    if ! check_installed "glances"; then
        upgrade_str="--upgrade"
    fi
else
    echo "Installing Glances via Python pip..."
fi

# pip install glances[action,browser,cloud,cpuinfo,chart,docker,export,folders,gpu,ip,raid,snmp,web,wifi]
install_cmd="pip install ${upgrade_str} glances"
if [ -n "${INSTALL_MODULES}" ]; then
  install_cmd="${install_cmd}[${INSTALL_MODULES}]"
fi
if ! do_with_root bash -c "${install_cmd}"; then
    exit 1
fi

echo "Running Glances daemon..."
if ! glances --webserver --time 30; then
  echo "Glances exited."
fi

echo "Glances installed."
exit 0
