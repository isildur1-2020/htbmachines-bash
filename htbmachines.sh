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

htbmachines="data.js"
htbmachinesAuxFile="data-aux.js"
htbmachinesDataURL="https://htbmachines.github.io/bundle.js"
declare -i parameter_counter=0

function printResponse() {
  response="$1"
  if [ "$response" != "" ]; then
    echo -e "\n$response\n"
  else
    echo -e "\n${redColour}Sorry, we could not find any machine.${endColour}\n"
    exit 1
  fi
}
function getMachineNamesByDifficulty() {
  echo -e "\n${yellowColour}[+] Searching machine names by difficulty '$machineDifficulty':${endColour}"
  machineNames="$(cat $htbmachines | grep -iB 5 "dificultad: \"$machineDifficulty\"" | grep "name: " | awk '{print $2}' | tr -d '",' | column)"
  printResponse "$machineNames"
  exit 0
}

function showHelpPanel() {
  echo -e "\n${yellowColour}[+]${endColour}${grayColour} How to use?${endColour}"
  echo -e "\t${purpleColour}- d${endColour}${grayColour} Get machine names by difficulty${endColour}"
  echo -e "\t${purpleColour}- h${purpleColour}${grayColour} Show help panel${endColour}"
  echo -e "\t${purpleColour}- i${endColour}${grayColour} Get machine name by ip address${endColour}"
  echo -e "\t${purpleColour}- m${endColour}${grayColour} Get machine info by machine name${endColour}"
  echo -e "\t${purpleColour}- o${endColour}${grayColour} Get machine names by operative system${endColour}"
  echo -e "\t${purpleColour}- s${endColour}${grayColour} Get machine names by skill${endColour}"
  echo -e "\t${purpleColour}- u${endColour}${grayColour} Update database${endColour}"
  echo -e "\t${purpleColour}- y${endColour}${grayColour} Get youtube link by machine name${endColour}\n"
  exit 0
}

function getMachineNameByIp() {
  echo -e "\n${yellowColour}[+] Searching machine name by ip address '$ipAddress':${endColour}"
  machineName="$(cat $htbmachines | grep -EB 3 "ip: \"$ipAddress\"" | grep "name: " | awk '{print $2}' | tr -d '",')"
  printResponse "$machineName"
  exit 0
}

function getMachineInfoByName() {
  echo -e "\n${yellowColour}[+] Searching machine info by machine name '$machineName':${endColour}"
  machineInfo="$(cat $htbmachines | awk "/name: \"$machineName\"/,/resuelta: /" | grep -vE "id|sku|youtube|resuelta" | sed 's/^ *//' | tr -d '",')"
  printResponse "$machineInfo"
  exit 0
}

function getMachineNamesByOS() {
  echo -e "\n${yellowColour}[+] Searching machine name by operative system '$OS':${endColour}"
  machineNames="$(cat $htbmachines | grep -i "so: \"$OS\"" -B 4 | grep "name" | awk '{print $2}' | tr -d '",' | column)"
  printResponse "$machineNames"
  exit 0
}

function getMachineNamesBySkill() {
  echo -e "\n${yellowColour}[+] Searching machine names by skill '$skill':${endColour}"
  machineNames="$(cat $htbmachines | grep "skills: " -B 6 | grep -iB 6 "$skill" | grep "name: " | awk '{print $2}' | tr -d '",' | column)"
  printResponse "$machineNames"
  exit 0
}


function downloadData() {
  echo -e "${yellowColour}[!] Downloading htbmachines data...${endColour}"
  curl -s $1 > $2
  js-beautify $2 | sponge $2
  echo -e "${greenColour}[!] htbmachines data was downloaded succesfully!${endColour}"
}

function updateHtbmachines() {
  if [ ! -f $htbmachines  ]; then
    downloadData $htbmachinesDataURL $htbmachines
  else
    echo -e "${yellowColour}[!] The file is already exists, downloading a copy to compare...${endColour}"
    downloadData $htbmachinesDataURL $htbmachinesAuxFile
    md5LocalData=$(md5sum $htbmachines | awk '{print $1}')
    md5AuxData=$(md5sum $htbmachinesAuxFile | awk '{print $1}')
    if [ "$md5LocalData" != "$md5AuxData" ]; then
      echo -e "${redColour}[!] The file are not equal, updating htbmachines data...${endColour}"
      cp $htbmachinesAuxFile $htbmachines
    else
      echo -e "${greenColour}[+] The files are equal, there are not updates."
    fi
    rm $htbmachinesAuxFile
  fi
}

function getYoutubeLinkByName() {
  echo -e "\n${yellowColour}[+] Searching youtube link by name '$machineName':${endColour}"
  machineLink="$(cat $htbmachines | awk "/name: \"$machineName\"/,/youtube: /" | tail -n 1 | awk 'NF {print $NF}' | tr -d '",')"
  printResponse "$machineLink"
  exit 0
}

function getMachineNamesByDifficultyAndOS() {
  echo -e "\n${yellowColour}[+] Searching machines names by difficulty '$machineDifficulty' and operative system '$OS':${endColour}"
  machineNames="$(cat $htbmachines | grep -i "so: \"$OS\"" -C 4 | grep -i "dificultad: \"$machineDifficulty\"" -B 5 | grep "name: " | awk '{print $2}' | tr -d '",' | column)"
  printResponse "$machineNames"
}

while getopts "d:m:ui:y:o:s:h" arg; do
  case $arg in
    d) machineDifficulty=$OPTARG;
       parameter_counter+=1
       ;;
    h) showHelpPanel;;
    i) ipAddress=$OPTARG;
       getMachineNameByIp;;
    m) machineName=$OPTARG;
       getMachineInfoByName;;
    o) OS=$OPTARG;
       parameter_counter+=5
       ;;
    s) skill=$OPTARG;
       getMachineNamesBySkill;;
    u) updateHtbmachines;;
    y) machineName=$OPTARG;
       getYoutubeLinkByName;;
    ?) showHelpPanel
       exit 1
       ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  getMachineNamesByDifficulty
elif [ $parameter_counter -eq 5 ]; then
  getMachineNamesByOS
elif [ $parameter_counter -eq 6 ]; then
  getMachineNamesByDifficultyAndOS
else
  showHelpPanel
fi
