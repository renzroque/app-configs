#!/bin/bash

# Oberthur Card Systems
# User launch script
# created by: Michael Remus G. Gaerlan
# creation date: 10-18-2004

# variable initialization
VER=1.0
LAUNCH=UserServer
CWDIR=`pwd`
LPATH=com/ocs/simplicate/service/user
LOG=log4j.UserBL.properties
PORT=7553
CMD=-s
PFLAG=false
LFLAG=false
KILL=UserBL
SIMPLICATE=/home/spcorgn/services

: export ${USERPID:=0}

# helper functions
promptHelp ()
{

    echo ""
    echo "$0 version ${VER}"
    echo "Launcher script for ${LAUNCH}"
    echo ""
    echo "Usage: ${0} [OPTION]..."
    echo ""
    echo "options:"
    echo " -t            stop/terminate ${LAUNCH}."
    echo " -s            start/activate ${LAUNCH}."
    echo " -h            this help message."
    echo " -p [port]     ORB port number. default is ${PORT}. ex -p ${PORT}."
    echo " -l [path]     path of .jar and/or .war files to be included in CLASSPATH."
    echo ""
    echo "recommended variables:"
    echo ""
    echo "JAVA_HOME      java home directory. default /usr/java/j2sdk1.4.2_04"
    echo "CATALINA_HOME  tomcat home directory. default /usr/local/tomcat"
    echo "SIMPLICATE     simplicate deployment directory. default ota1.2"
    echo "CLASSPATH      java class path. default ."
    echo ""
    exit 1
}

# check env variables
echo ""
if [ -z ${JAVA_HOME} ]
then
    echo "Warning: JAVA_HOME not set. Using /usr/java/j2sdk1.4.2_04"
    export JAVA_HOME=/usr/java/j2sdk1.4.2_04
fi

if [ -z ${CATALINA_HOME} ]
then
    echo "Warning: CATALINA_HOME not set. Using /usr/local/tomcat"
    export CATALINA_HOME=/usr/local/tomcat
fi

if [ -z ${CATALINA_OPTS} ]
then
    echo "Warning: TOMCAT server may start without optimized options..."
    export CATALINA_OPTS='-server -Xmn100M -Xms500M -Xmx500M'
fi

if [ -z ${SIMPLICATE} ]
then
#    TEMP=`dirname $0`
#    cd ${TEMP}
    TEMP=`pwd`
#    TEMP=`dirname ${TEMP}`
    echo "Warning: SIMPLICATE not set. Using ${TEMP}"
    export SIMPLICATE=${TEMP}
    cd ${CWDIR}
fi

if [ -z ${CLASSPATH} ]
then
    echo "Warning: CLASSPATH not set. Using ."
    export CLASSPATH=.
fi

LIB=${CATALINA_HOME}/lib

# script sequence

# command line argument filtering
for i in "$@"; do

    case ${i} in
        "-s")
            CMD=${i}
            ;;

        "-t")
            CMD=${i}
            ;;

        "-h")
            promptHelp
            ;;

        "-p")
            PFLAG=true
            ;;

        "-l")
            LFLAG=true
            ;;

        *)
            if [ x"${PFLAG}" == xtrue ]; then
                PORT=${i}
                PFLAG=false
            elif [ x"${LFLAG}" == xtrue ]; then
                LIB=${i}
                LFLAG=false
            else
                echo "${i} - invalid option"
                echo "type $0 -h for usage"
                echo ""
                exit 1
            fi
            ;;

    esac

done

# perform stop
if [ x"$PHONEBOOKPID" != x"0" ]; then

    kill -9 $PHONEBOOKPID
    RESULT=$?

    if [ x"$RESULT" == x"0" ]; then

        echo "Message: Successfully killed ${LAUNCH} ${PHONEBOOKPID}."
        # check if CMD is stop.
        if [ x"$CMD" == x"-t" ]; then

            # reset pid keeper
            export PHONEBOOKPID=0
        fi

    else
        echo "Warning: Process ID ${PHONEBOOKPID} was not found."
    fi

fi

# reset pid keeper
export PHONEBOOKPID=0

# get process id
#PID=`ps -ef | grep -v "grep" | grep "$LAUNCH" | grep -v "$0" | awk '{print $2}'`
PID=`ps -ef | grep -v "grep" | grep "$KILL" | grep "$LOGNAME " | grep -v "$0" | awk '{print $2}'`

if [ x"$PID" != x"" ]; then

    echo "Message: Attempting to find ${LAUNCH} process manually..."
    for i in $PID; do
        ps -ef | grep $i | grep -v "grep"
        kill -9 $i
    done

    echo "Message: ${LAUNCH} successfully stopped."
    # check if CMD is stop.
    if [ x"$CMD" == x"-t" ]; then
        echo ""
        exit 0
    fi

else
    if [ x"$CMD" == x"-t" ]; then
        echo "Error: ${LAUNCH} process was not found. Nothing to stop."
        echo ""
        exit 1
    fi

fi

# check if port is in use
netstat -an | grep :${PORT}
if [ "$?" == "0" ]; then
    echo "Error: Port ${PORT} is already in use."
    echo ""
    exit 1
fi

# set additional variables Service directory
SBL=${SIMPLICATE}
if [ ! -d ${SBL} ]; then
        echo "Error: Cannot find appropriate directory for launch. Please define correct SIMPLICATE variable"
        echo "type $0 -h for usage"
        echo ""
        exit 1
fi

cd ${SBL}

echo "Message: Services located at ${SBL}."

# backup classpath
DCLASSPATH=CLASSPATH

# update classpath with ${SIMPLICATE}/lib
TEMP=`ls lib/*.[wj]ar`
for i in ${TEMP}; do
    CLASSPATH=${CLASSPATH}:${SBL}/${i}
done

# add additional libraries to classpath if necessary
if [ -d ${LIB} ]; then
    TEMP=`ls ${LIB}/*.[wj]ar`
    for i in ${TEMP}; do
        CLASSPATH=${CLASSPATH}:${i}
    done
fi

if [ ! -d classes ]; then
    echo "Error: Cannot find classes directory. Launch aborted."
    export CLASSPATH=${DCLASSPATH}
    cd ${CWDIR}
    echo ""
    exit 1
fi

cd classes

#if [ -G ${LOG} ]; then
#    echo "Changing log settings..."
#    cp ${LOG} ${LOG}.old
#    sed -e /log4j.appender.A2.File*/c\log4j.appender.A2.File=${SIMPLICATE}\/logs\/${LAUNCH}.txt ${LOG} > ${LOG}.tmp
#    mv ${LOG}.tmp ${LOG}

#    echo "Log files set to ${SIMPLICATE}/logs/${LAUNCH}.txt"
#fi


echo "Message: inside "`pwd`"."

# launch it
echo "Message: Launching $LAUNCH"
java -Dorg.omg.CORBA.ORBSingletonClass=org.openorb.CORBA.ORBSingleton -Dorg.omg.CORBA.ORBClass=org.openorb.CORBA.ORB -Dlog4j.configuration=${LOG} ${LPATH}/${LAUNCH} ${CATALINA_OPTS} -ORBPort=${PORT} &

if [ "$?" -ne "0" ]; then
    echo "Error: Cannot execute ${LAUNCH}"
    cd $SCR
    export CLASSPATH=$DUMMY
    cd ${CWDIR}
    echo ""
    exit 1
fi

export PHONEBOOKPID=$!

echo "Message: ${LAUNCH} started. PID=${PHONEBOOKPID}"
export CLASSPATH=$DUMMY

cd ${CWDIR}
echo ""
exit 0