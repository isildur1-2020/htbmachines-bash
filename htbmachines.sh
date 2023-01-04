#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function hideCursor() {
	tput civis
}

function showCursor() {
	tput cnorm
}

function ctrl_c() {
	echo -e "${redColour}[!] Exiting...${endColour}"
	showCursor
	exit 0
}
trap ctrl_c INT

htbmachinesLocalFile="data.js"
htbmachinesAuxFile="data-aux.js"
htbmachinesDataURL="https://htbmachines.github.io/bundle.js"
declare -i parameter_counter=0

function showHelpPanel() {
	echo -e "\n${yellowColour}[+]${endColour}${grayColour} How to use?${endColour}"
	echo -e "\t${purpleColour}u)${endColour}${grayColour} Update database${endColour}"
	echo -e "\t${purpleColour}m)${endColour}${grayColour} Search for a machine name${endColour}"
	echo -e "\t${purpleColour}i)${endColour}${grayColour} Search for a IP address${endColour}"
	echo -e "\t${purpleColour}h)${purpleColour}${grayColour} Show help panel${endColour}"
}

function downloadData() {
	echo -e "${yellowColour}[!] Downloading htbmachines data...${endColour}"
	curl -s $1 > $2
	js-beautify $2 | sponge $2
	echo -e "${greenColour}[!] htbmachines data was downloaded succesfully!${endColour}"
}

function updateFiles() {
	hideCursor
	if [ ! -f $htbmachinesLocalFile  ]; then
		downloadData $htbmachinesDataURL $htbmachinesLocalFile
	else
		echo -e "${yellowColour}[!] The file is already exists, downloading a copy to compare...${endColour}"
		downloadData $htbmachinesDataURL $htbmachinesAuxFile
		md5LocalData=$(md5sum $htbmachinesLocalFile | awk '{print $1}')
		md5AuxData=$(md5sum $htbmachinesAuxFile | awk '{print $1}')
		if [ "$md5LocalData" != "$md5AuxData" ]; then
			echo -e "${redColour}[!] The file are not equal, updating htbmachines data...${endColour}"
			cp $htbmachinesAuxFile $htbmachinesLocalFile
		else
			echo -e "${greenColour}[+] The files are equal, there are not updates."
		fi
		rm $htbmachinesAuxFile
	fi
	showCursor
}

function searchMachine() {
	machineName=$1
	cat $htbmachinesLocalFile | awk "/name: \"$machineName\"/,/resuelta: /" | grep -vE "id|sku|youtube" | sed 's/^ *//' | tr -d '",'
}

function searchByIP() {
	ipAddress=$1
	machineName="$(cat $htbmachinesLocalFile | grep "ip: \"$ipAddress\"" -B 4 | grep "name: " | sed 's/^ *//' | tr -d '",' | awk '{print $2}')"
	if [ "$machineName" != "" ]; then
		echo -e "${greenColour}Info found succesfully.${endColour}"
		echo -e "${greenColour}The ip $ipAddress correspond to $machineName machine.${endColour}"
	else 
		echo -e "${redColour}The name machine could not be found.${endColour}"
	fi
}

function findLinkByIP() {
	ipAddress=$1
	machineLink="$(cat $htbmachinesLocalFile | awk "/ip: \"$ipAddress\"/,/youtube: /" | tail -n 1 | awk 'NF {print $NF}' | tr -d '",')"
	if [ $machineLink != "" ]; then
		searchByIP $ipAddress
		echo -e "${greenColour}The youtube link for this machine is: $machineLink${endColour}"
	else
		echo -e "${redColour}Machine not found.${endColour}"
	fi
}

while getopts "m:ui:y:h" arg; do
	case $arg in
		m) machineName=$OPTARG; let parameter_counter+=1;;
		u) let parameter_counter+=2;;
		i) ipAddress=$OPTARG; let parameter_counter+=3;;
		y) ipAddress=$OPTARG; let parameter_counter+=4;;
		h) showHelpPanel;;
	esac
done

if [ $parameter_counter -eq 1 ]; then
	searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
	updateFiles
elif [ $parameter_counter -eq 3 ]; then
	searchByIP $ipAddress
elif [ $parameter_counter -eq 4 ]; then
	findLinkByIP $ipAddress
else
	showHelpPanel
fi 
