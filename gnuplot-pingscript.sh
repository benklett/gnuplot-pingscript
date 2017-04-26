#!/bin/bash
# GNUPlot pingscript by Benjamin Klettbach (b<dot>klettbach<at>gmail<dot>com)

dataDir="gnuplot-pingscript-data"

function start() {

    printInit
    checkDeps

    cacheDate=$(date +%Y-%m-%d_%H-%M)
    
    if [ ! -d "${1}" ]
    then
        getAddress $1
        createDirs
        startPing $2 $3
        
        runSed
        runGNUPlot $4 $5 $6
    else
        sessionDataDir="$1"
        runSed
        runGNUPlot $2 $3 $4
    fi

    echo "Finished."
}

function printInit() {

    echo "Welcome to the GNUPlot pingscript"
    echo ""
}

function checkDeps() {

    local plot=$(whereis gnuplot)
    if [ "${plot}" == "gnuplot:" ]
    then
        echo "Please install gnuplot and/or make sure it is on your PATH"
    fi

    local sed=$(whereis sed)
    if [ "${sed}" == "sed:" ]
    then
        echo "Please install sed and/or make sure it is on your PATH"
    fi
}

function getAddress() {
    address=$1

    if [ -z "${address}" ]
    then
        echo "Please enter the address/IP you want to ping (Default: google.com):"
        read address
        if [ -z "${address}" ]
        then
            address="google.com"
        fi
    fi

    sessionName="${address}_${cacheDate}"
    sessionDataDir="${dataDir}/${sessionName}"
    echo ""
}

function createDirs() {

    echo "Creating gnuplot-pingscript-data directory and address directory."
    mkdir -p "${dataDir}"
    mkdir -p "${sessionDataDir}"
    echo ""
}

function startPing() {

    local interval=$1
    if [ -z "${interval}" ]
    then
        echo "Please enter the interval for the ping (Default: 0.2):"
        read interval
        if [ -z "${interval}" ]
        then
            interval="0.2"
        fi
    fi

    local count=$2
    if [ -z "${count}" ]
    then
        echo "Please enter the ping count (Default: 2000):"
        read count
        if [ -z "${count}" ]
        then
            count="2000"
        fi
    fi

    echo "Running ping ..."
    if [ 1 -eq $(echo "${interval} < 0.2" | bc) ]
    then
        echo "Asking for root permissions to ping that fast ..."
        local user=${USER}
        sudo ping -D -i ${interval} -c ${count} ${address} > "${sessionDataDir}/ping.txt"
        sudo chown "${user}:${user}" "${sessionDataDir}/ping.txt"
    else
        ping -D -i ${interval} -c ${count} ${address} > "${sessionDataDir}/ping.txt"
    fi
    echo "Ping finished."
}

function runSed() {

    cat <<- EOF > ${dataDir}/sed.cfg
s/time=/time= /g
s/^[^\[]/#&/g
EOF

    sed -f ${dataDir}/sed.cfg ${sessionDataDir}/ping.txt > ${sessionDataDir}/processed.txt

    grep -v '#' ${sessionDataDir}/processed.txt > ${sessionDataDir}/processed-cached.txt
    mv ${sessionDataDir}/processed-cached.txt ${sessionDataDir}/processed.txt

    if [ -eq $(sed -n '1{p;q}' ${sessionDataDir}/processed.txt | cut -d' ' -f 10) "ms" ]
    then
        cat ${sessionDataDir}/processed.txt | cut -d' ' -f 1,9 > ${sessionDataDir}/processed-cached.txt
    else
        cat ${sessionDataDir}/processed.txt | cut -d' ' -f 1,10 > ${sessionDataDir}/processed-cached.txt
    fi
    mv ${sessionDataDir}/processed-cached.txt ${sessionDataDir}/processed.txt

    rm ${dataDir}/sed.cfg
}

function runGNUPlot {

    cat <<- EOF > ${dataDir}/gnuplot.cfg
#Format Output

set title "Ping History"
set ylabel 'Ping Latency'
set xlabel "Period of time (Date)"
set timestamp "%Y-%m-%d %H:%M" offset 80,-2 font "Open Sans"
#set ytics autofreq 0, +50, 8000; rotate=90
set format x "%Y-%m-%d\n%H:%M:%S"; rotate=90
set xdata time

#Format Input

set timefmt "[%s]"
set tic scale 0
set yrange [RANGEY:]
set grid
set terminal png noenhanced size SIZEX,SIZEY
set output "OUTPUT"
plot "FILE" u 1:2 w dots title "Ping from FILE", "FILE" u 1:2 smooth sbezier title "Smoothed with sbezier"
EOF

    local rangey=$1
    if [ -z "${rangey}" ]
    then
        echo "Please enter where the plot should start from (Y-Axis)(Default: 0):"
        read rangey
        if [ -z "${rangey}" ]
        then
            rangey="0"
        fi
    fi
    sed -e "s/RANGEY/${rangey}/g" ${dataDir}/gnuplot.cfg > ${dataDir}/edited-gnuplot.cfg
    mv ${dataDir}/edited-gnuplot.cfg ${dataDir}/gnuplot.cfg

    local sizey=$2
    if [ -z "${sizey}" ]
    then
        echo "Please enter the png height (Default: 720):"
        read sizey
        if [ -z "${sizey}" ]
        then
            sizey="720"
        fi
    fi
    sed -e "s/SIZEY/${sizey}/g" ${dataDir}/gnuplot.cfg > ${dataDir}/edited-gnuplot.cfg
    mv ${dataDir}/edited-gnuplot.cfg ${dataDir}/gnuplot.cfg

    local sizex=$3
    if [ -z "${sizex}" ]
    then
        echo "Please enter the png width (Default: 1280):"
        read sizex
        if [ -z "${sizex}" ]
        then
            sizex="1280"
        fi
    fi
    sed -e "s/SIZEX/${sizex}/g" ${dataDir}/gnuplot.cfg > ${dataDir}/edited-gnuplot.cfg
    mv ${dataDir}/edited-gnuplot.cfg ${dataDir}/gnuplot.cfg

    sed -e "s/FILE/${sessionDataDir//\//\\/}\/processed.txt/g" ${dataDir}/gnuplot.cfg > ${dataDir}/edited-gnuplot.cfg
    mv ${dataDir}/edited-gnuplot.cfg ${dataDir}/gnuplot.cfg
    sed -e "s/OUTPUT/${sessionDataDir//\//\\/}\/out.png/g" ${dataDir}/gnuplot.cfg > ${dataDir}/edited-gnuplot.cfg
    mv ${dataDir}/edited-gnuplot.cfg ${dataDir}/gnuplot.cfg

    echo "Running GNUPlot ..."
    gnuplot ${dataDir}/gnuplot.cfg

    rm ${dataDir}/gnuplot.cfg
}

start $1 $2 $3 $4 $5 $6
