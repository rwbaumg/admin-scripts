#!/bin/bash
#
#	Linux-Bench CPU Benchmark Script
#	(C) 2013-2017 ServeTheHome.com and ServeThe.biz
#
# 	Linux-Bench - A System benchmark and comparison tool created by the STH community.
#
#	Linux-Bench is a sscript that runs hardinfo, Unixbench 5.1.3, c-ray 1.1, STREAM, OpenSSL, sysbench (CPU),
#	crafty, redis, NPB, NAMD, and 7-zip benchmarks without manual intervention.
#
#	Linux-Bench must be run as root or using a su prompt to automate download and installation of benchmarks
#
#	For more information go:
#	http://linux-bench.com
#
# 	Authors: Patrick Kennedy, Charles Nguyen (Chuckleb), Patriot, nitrobass24, mir, Frank DiDonato (LOGiCELL, Inc.)  
#
#	Latest development versions are available on the GitHub site:  https://github.com/STH-Dev/linux-bench/
#
#   	If you find bugs, verify you are on the latest version and then post in:
#	https://forums.servethehome.com/index.php?forums/linux-bench/
#
#	To view your results, check the reference ID at the end of the log file generated. You can copy and paste
#	the ID number here: http://linux-bench.com/parser.html and see parsed results.
################################################################################################################################

#Current Version
rev='12.19'

version()
{
cat << EOF
##############################################################
#  (c) 2013-2017 ServeTheHome.com and ServeThe.biz
#
#	Linux-Bench $rev
#	- Linux-Bench the STH Benchmark Suite
###############################################################

EOF
}


usage()
{
cat << EOF

usage: $0

This is the STH benchmark suite.

ARGS:
        ARG1 - none required for now
        ARG2 - none required for now
        ARG3 - none required for now

OPTIONAL ARGS:
        ARG -- script_option_1 script_option-2

OPTIONS:
	-h	help (usage info)
    	-V	Version of Linux-Bench
    	-p 	Private Result, results will not be in the public database
    	-e	Email results, a perfect pairing with private results.
    		use -e email@email.net


ENVIRONMENT VARIABLES:

VIRTUAL = If unset, value is FALSE. Set to TRUE if running virtualized (automatically set for Docker)

EOF
}


# Verify if the script is executed with Root Privileges #
rootcheck()
{
	if [[ $EUID -ne 0 ]]; then
   		echo "This script must be run as root"
		echo "Ex. "sudo ./linux-bench.sh""
		exit 1
	fi
}


#Set Functions
setup()
{
	benchdir=`pwd`
	NEED_PTS=1

	date_str="+%Y_%m%d_%H%M%S"
	full_date=`date $date_str`
	host=$(hostname)
	log="linux-bench"$rev"_"$host"_"$full_date.log
	if [ -f /.dockerinit ] ; then
		log=/data/"linux-bench"$rev"_"$host"_"$full_date.log
	fi

	if [ -n "$isprivate" ]; then
		echo $isprivate
	fi

	if [ -n "$email" ]; then
		echo $email
	fi

	#outdir=$host"_"$full_date
	#mkdir $outdir
}


# Update and install required packages (Debian)
Update_Install_Debian()
{
	apt-get update
	apt-get -y install build-essential libx11-dev libglu-dev hardinfo sysbench unzip expect php7.0-curl php7.0-common php7.0-cli php7.0-gd libfpdi-php gfortran curl
	mkdir -p /usr/tmp/
	rm /etc/apt/sources.list.d/linuxbench.list
}


# Update and install required packages (CentOS/RHEL)
Update_Install_RHEL()
{
	rpm -Uhv http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	rpm -Uhv http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
	yum -y groupinstall "Development Tools" && yum -y install wget sysbench unzip libX11 perl-Time-HiRes mesa-libGLU hardinfo expect php-common glibc.i686 gfortran curl
}


# Detects which OS and if it is Linux then it will detect which Linux Distribution.
whichdistro()
{
	OS=`uname -s`
	REV=`uname -r`
	MACH=`uname -m`

	if [ "${OS}" = "SunOS" ] ; then
		OS=Solaris
		DIST=Solaris
		ARCH=`uname -p`
		OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
	elif [ "${OS}" = "AIX" ] ; then
		DIST=AIX
		OSSTR="${OS} `oslevel` (`oslevel -r`)"

	elif [ "${OS}" = "Linux" ] ; then
		KERNEL=`uname -r`

		if [ -f /etc/redhat-release ] ; then
			DIST='RedHat'
			PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`

		elif [ -f /etc/centos-release ] ; then
			DIST='CentOS'
			PSUEDONAME=`cat /etc/centos-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/centos-release | sed s/.*release\ // | sed s/\ .*//`

		elif [ -f /etc/SuSE-release ] ; then
			DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
			REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`

		elif [ -f /etc/mandrake-release ] ; then
			DIST='Mandrake'
			PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
			REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`

		elif [ -f /etc/debian_version ] ; then
			DIST="Debian"
			PSUEDONAME=`cat /etc/debian_version`
				REV=""
			if [ `grep DISTRIB_ID= /etc/lsb-release | cut -d"=" -f2` = "Ubuntu" ] ; then
				DIST="Ubuntu"
				UBUNTU_RELEASE=`lsb_release -sc`
				REPO1="deb http://us.archive.ubuntu.com/ubuntu/ "
				REPO1END=" universe"
				echo $REPO1 $UBUNTU_RELEASE $REPO1END > /etc/apt/sources.list.d/linuxbench.list
			fi

		elif [ -f /etc/UnitedLinux-release ] ; then
			DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"

		else
			DIST='Not detected'
		fi

		OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"
	fi
}


# Update and install required packages
dlDependancies()
{
	if [ -f /.dockerinit ] ; then
	echo "In a Docker container, no updates run."
	VIRTUAL="TRUE"
	elif [ "${DIST}" = "CentOS" ] ; then
	Update_Install_RHEL
	elif [ "${DIST}" = "RedHat" ] ; then
	Update_Install_RHEL
	elif [ "${DIST}" = "Debian" ] || [ "${DIST}" = "Ubuntu" ] ; then
	Update_Install_Debian
	fi
}


# Display script output and append to log
benchlog()
{
	exec > >(tee --append $log)
        echo $ref >> $log
	exec 2>&1
	echo ${OSSTR}
}


extract()
{
	if [ -e ./$appbin ] ; then
		echo "$apptgz already installed"
	elif [ -e ./$apptgz ] ; then
		tar $tgzstring $apptgz
	else
		wget $appdlpath
		tar $tgzstring $apptgz
	fi
}


#System information and log capture.
sysinfo()
{
	eval "strings `which lscpu`" | grep -q version ;
	if [ $? = 0 ] ; then
		lscpu
		lscpu -V
		lscpu -e
	else
		lscpu;
	fi
	: ${VIRTUAL:=FALSE}
	echo "VIRTUAL="$VIRTUAL


# Check to see if the CPU is an Intel/AMD or ARM
# This is a simple check for now.

cpu_check=$(grep 'CPU architecture' /proc/cpuinfo)
if [ $? -ne 0 ] ; then
	CPU=x86
else
	CPU=ARM;
fi

echo "CPU="$CPU

echo "Linux-Bench Version="$rev
}

proc_define()
{
		# Physical sockets
	sockets=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)

        # Physical Cores
        if [[ $CPU == "x86" ]] ; then
                procs=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
                pcores=$(grep "cpu cores" /proc/cpuinfo |sort -u |cut -d":" -f2)
                cores=$((procs*pcores))
        elif [[ $CPU == "ARM" ]] ; then
                cores=$(grep "processor" /proc/cpuinfo | wc -l)
        else
                echo "Unknown CPU"
        fi

	# Virtual Cores (include threads)
	vcores=$(grep "processor" /proc/cpuinfo | wc -l)
	threads=$vcores
	nproc=$vcores

}


# HardInfo
hardi()
{
	cd $benchdir
	echo "Running HardInfo test"
	hardinfo --generate-report --report-format text
}

# UnixBench 5.1.3
ubench()
{
	cd $benchdir
	echo "Building UnixBench"
	wget -N http://files.linux-bench.com/lb/UnixBench5.1.3.tgz
	wget -N http://files.linux-bench.com/lb/fix-limitation.patch
	tar -zxf UnixBench5.1.3.tgz

	cd UnixBench
	mv ../fix-limitation.patch .
	make -j$(nproc)
	patch Run fix-limitation.patch
	echo "Running UnixBench"
	./Run dhry2reg whetstone-double syscall pipe context1 spawn execl shell1 shell8 shell16
	cd $benchdir
	rm -rf UnixBench* fix-limitation.patch
}

# C-Ray 1.1
cray()
{
	cd $benchdir

	appbase=c-ray-1.1
	apptgz=c-ray-1.1.gz
	tgzstring=xfz
	appbin=$appbase/c-ray-mt
	appdlpath=http://files.linux-bench.com/lb/$apptgz
	extract

	echo "Running C-Ray test"
	cd c-ray-1.1 && make
	echo "c-ray Easy Test"
	cat scene | ./c-ray-mt -t $threads -s 7500x3500 > foo.ppm
	echo "c-ray Medium Test"
	cat sphfract | ./c-ray-mt -t $threads -s 1920x1200 -r 8 > foo.ppm
	echo "c-ray Hard Test"
	cat sphfract | ./c-ray-mt -t $threads -s 3840x2160 -r 8 > foo.ppm
	cd $benchdir
	rm -rf $appbase*
}

# STREAM by Dr. John D. McCalpin
stream()
{
	cd $benchdir
	echo "Building STREAM"

	if [ -e stream.c ] ; then
		echo "Stream downloaded"
	else
		wget -N http://www.cs.virginia.edu/stream/FTP/Code/stream.c
	fi

	gcc stream.c -O3 -march=native -fopenmp -o stream-me

	export OMP_NUM_THREADS=$cores
	export GOMP_CPU_AFFINITY=0-$((cores-1))
	echo $GOMP_CPU_AFFINITY

	echo "Running STREAM test"
	./stream-me

	cd $benchdir
	rm -rf stream-me stream.c
}

# OpenSSL
OSSL()
{
	cd $benchdir

	appbase=openssl-1.0.1g
	apptgz=openssl-1.0.1g.tar.gz
	tgzstring=xfz
	appbin=$appbase/apps/openssl
	appdlpath=http://www.openssl.org/source/$apptgz
	extract

	cd openssl-1.0.1g/
	echo "Building OpenSSL"
	./config no-zlib 2>&1 >> /dev/null
	make 2>&1 >> /dev/null
	echo "Running OpenSSL test"
 	./apps/openssl speed rsa4096 -multi $nproc

	cd $benchdir
	rm -rf openssl*
}

crafty()
{
	cd $benchdir
   	wget -N http://www.craftychess.com/crafty-23.4.zip
   	unzip -o crafty-23.4.zip
   	cd crafty-23.4/
   	export target=LINUX
   	export CFLAGS="-Wall -pipe -O3 -fomit-frame-pointer $CFLAGS"
   	export CXFLAGS="-Wall -pipe -O3 -fomit-frame-pointer"
   	export LDFLAGS="$LDFLAGS -lstdc++"
   	make crafty-make
   	chmod +x crafty
   	./crafty bench end

	cd $benchdir
	rm -rf crafty*
}



# sysbench CPU test prime
sysb()
{
	cd $benchdir
   	echo "Running sysbench CPU Single Thread"
   	sysbench --test=cpu --cpu-max-prime=30000 run
   	echo "Running sysbench CPU Multi-Threaded"
   	sysbench --num-threads=$nproc --test=cpu --cpu-max-prime=300000 run
}


# redis Benchmark based on feedback. Next step is to add memchached as seen here: http://oldblog.antirez.com/post/redis-memcached-benchmark.html
red()
{
	cd $benchdir
	echo "Building Redis"

	wget http://download.redis.io/redis-stable.tar.gz
	tar xzf redis-stable.tar.gz && cd redis-stable && make install
	cp utils/redis_init_script /etc/init.d/redis_6379
	mkdir -p /var/redis/6379
	wget http://files.linux-bench.com/lb/6379.conf
	mkdir -p /etc/redis
	cp ./6379.conf /etc/redis

	service redis_6379 start

   	# Original redis benchmark set/ get test

	echo "Running Redis test"
	redis-benchmark -n 1000000 -t set,get -P 32 -q -c 200

	BIN=redis-benchmark

	payload=32
	iterations=10000
	keyspace=100000

	for clients in 1 5 10 25 50 75 100
	do
		SPEED=0
		for dummy in 0 1 2
			do
				S=$($BIN -n $iterations -r $keyspace -d $payload -c $clients | grep 'per second' | tail -1 | awk '{print $1}')
				VALUE=$(echo $S | awk '{printf "%.0f",$1}')
				if [ $(($VALUE > $SPEED)) != 0 ]
					then
					SPEED=$VALUE
				fi
			done
		echo "$clients $SPEED"
	done

	redis-cli shutdown

	cd $benchdir
	rm -rf redis* /etc/redis /var/redis* /usr/local/bin/redis-* /etc/init.d/redis_*

}


# NPB Benchmarks
NPB()
{
	cd $benchdir

	apptgz=NPB3.3.1.tar.gz
	appbin=NPB3.3.1/NPB3.3-OMP
	appdlpath=http://files.linux-bench.com/lb/$apptgz
	tgzstring=xfz
	extract

	cd NPB3.3.1/NPB3.3-OMP/
	echo "Building NPB"

   	# Use the provided makefile definitions
   	cp config/NAS.samples/make.def.gcc_x86 config/make.def

	# Define which tests to build
	echo "ft A" >> config/suite.def
	#echo "mg A" >> config/suite.def
	#echo "sp A" >> config/suite.def
	#echo "lu A" >> config/suite.def
	echo "bt A" >> config/suite.def
	#echo "is A" >> config/suite.def
	#echo "ep A" >> config/suite.def
	#echo "cg A" >> config/suite.def
	#echo "ua A" >> config/suite.def
	#echo "dc A" >> config/suite.def

	make suite

	export OMP_NUM_THREADS=$cores

	echo "Running NPB tests"
	bin/bt.A.x
	bin/ft.A.x

	cd $benchdir
	rm -rf NPB*
}


# NAMD Benchmark http://www.ks.uiuc.edu/Research/namd/performance.html
NAMD()
{
	echo "Building NAMD"
	cd $benchdir

	appbase=NAMD_2.9_Linux-x86_64-multicore
	apptgz=NAMD_2.9_Linux-x86_64-multicore.tar.gz
	tgzstring=xfz
	appbin=$appbase/namd2
	appdlpath=http://files.linux-bench.com/lb/$apptgz
	extract

	appbase=apoa1
	apptgz=apoa1.tar.gz
	tgzstring=xfz
	appbin=$appbase/apoa1.pdb
	appdlpath=http://files.linux-bench.com/lb/$apptgz
	extract

	echo "Using" $threads "threads"
	echo "Running NAMD benchmark... (will take a while)"

	cd NAMD_2.9_Linux-x86_64-multicore
	timeperstep=$(./namd2 +p$threads +setcpuaffinity ../apoa1/apoa1.namd | grep "Benchmark time" | tail -1 | cut -d" " -f6)

	echo "Time per step" $timeperstep

	cd $benchdir
	rm -rf NAMD* apoa1*
}

# p7zip
p7zip()
{
	cd $benchdir

	appbase=p7zip_9.20.1
	apptgz=p7zip_9.20.1_src_all.tar.bz2
	tgzstring=xfj
	appbin=p7zip_9.20.1/bin/7za
	appdlpath=http://files.linux-bench.com/lb/$apptgz
	extract

	echo "Building p7zip"
	cd $appbase
	make 2>&1 >> /dev/null

	echo "Starting 7zip benchmark, this will take a while"
	bin/7za b >> output.txt

	compressmips=$(grep Avr output.txt | tr -s ' ' |cut -d" " -f4)
	decompressmips=$(grep Avr output.txt | tr -s ' ' |cut -d" " -f7)

	echo "Compress speed (MIPS):" $compressmips
	echo "Decompress speed (MIPS):" $decompressmips

	cd $benchdir
	rm -rf p7zip*
}

runBenches()
{
#Individual modules run below...comment them out to prevent them from running.
#echo ${iterations:=1} passes
#	while [ $iterations -gt 0 ] ; do
		echo "hardinfo"
		time hardi
		echo "ubench"
		time ubench
		echo "cray"
		time cray
		echo "stream"
		time stream
		echo "OSSL"
		time OSSL
		echo "sysbench"
		time sysb
		echo "redis"
		time red
		echo "NPB"
		time NPB
		echo "NAMD"
		time NAMD
		echo "p7zip"
		time p7zip
#		let iterations-=1
#	done
}



#	Runtime  This is where everything is actually run from and called...
#
# 	This is where a menu would go for runtime options...
#

main()
{
rootcheck

while getopts "hVRpe:" arg; do

  case $arg in
	h)
	usage
	exit 1
	;;
	V)
	version
	exit 1
	;;
	p)
	isprivate="Private Result"
	;;
	e)
        email="Send Linux-Bench result to: $OPTARG"
	;;
	\?)
     	usage
	exit 1
     	;;
  esac
done
	echo "setup"
	setup
	echo "version"
	version
	echo "whichdistro"
	whichdistro
	echo "dlDep"
	dlDependancies
	echo "benchlog"
	benchlog
	echo "derpinfo"
	sysinfo  exiting on sysinfo...
	sysinfo
	echo "proc_define"
	proc_define
	echo "run benches"
	runBenches
	echo "done"
}

push_data() {
  ref=$(date +%S%d$i%s)
  echo "ref_link: $ref"
  echo "See your results online at: http://linux-bench.com/display/$ref"
  mkdir tmpbench && cp $log tmpbench/.
  sleep 1s
#  curl -F file="@./tmpbench/$log" http://parser.linux-bench.com:3000/java-process/uploader -H "Connection: close"
  curl --form file="@./tmpbench/$log" --form press=Upload http://beta.linux-bench.com/upload_file/ --trace-ascii dumpfile

#Adding new script targets
  curl --form file="@./tmpbench/$log" --form press=Upload http://linux-bench.com/upload_file/ --trace-ascii dumpfile
#  curl -F file="@./tmpbench/$log" http://linux-bench.com:3000/java-process/uploader -H "Connection: close"
  rm -rf ./tmpbench/
  echo "ref_link: $ref"
}

# Execute everything in the script
main
push_data
