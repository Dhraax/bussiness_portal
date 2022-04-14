#! /bin/bash

declare -r redColour=`tput setaf 1`
declare -r greenColour=`tput setaf 2`
declare -r endColour=`tput sgr0`

declare -r DIR1="/path/directory"
declare -r DIR2="/path/directory"
declare -r DIRREPO="/path/directory"
declare -r NGINX="/etc/nginx"
declare -r ENV="master"
declare -r REPOPORTAL="git@#####.git"
declare -r REPO1="git@#####.git"
declare -r REPO2="git@#####.git"
declare -r SED="/bin/sed"
declare -r arg0="-i"

#trap CTRL+c
trap ctrl_c INT

function ctrl_c(){
    tput cnorm
    echo -e "\n\n${redColour}[!] Exiting...${endColour}"
    exit 1
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function gitClone(){
    
    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= Cleaning up directories...=${endColour}"
    rm -rf $DIR1
    rm -rf $DIR2
    rm -rf $NGINX/sites-enabled/SITE1
    rm -rf $NGINX/sites-enabled/SITE2
    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= Instalando repositorios.=${endColour}"
    git clone $REPO1 $DIR1
    git clone $REPO2 $DIR2
}

function gitPull(){

    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= UPDATING REPO 1.=${endColour}"
    git -C $DIR1 reset --hard
    git -C $DIR1 pull $REPO1 $ENV
    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= UPDATING REPO 2.=${endColour}"
    git -C $DIR1 reset --hard
    git -C $DIR2 pull $REPO2 $ENV
}

function setEnv(){

    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= Setting up API1.=${endColour}"
    cp $DIRREPO/SITE1/.env $DIR1

    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= Setting up API2.=${endColour}"
    cp $DIRREPO/SITE2-api/.env $DIR2

    echo -e "${greenColour}==============================${endColour}"
    echo -e "${greenColour}= Setting up NGINX.=${endColour}"
    cp -r $DIRREPO/nginx/nginx.conf $NGINX
    cp -r $DIRREPO/nginx/SITE1 $NGINX/sites-enabled/
    cp -r $DIRREPO/nginx/SITE2-api $NGINX/sites-enabled/
}

function pConfirm() {
  while true; do
    read -r -n 1 -p "${1:-Respuesta?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "[!][Error]: Check your answer"
    esac
  done
}

function setdomain() {
    echo -e "${greenColour}===============================${endColour}"
    echo -e "${greenColour}= Domain setup =${endColour}"
    while pConfirm = true; do
        echo -e "\n\n${greenColour}---- DOMAIN 1: ----${endColour}"
        read SITE1_DOMAIN
        echo -e "\n\n${greenColour}---- DOMAIN 2: ----${endColour}"
        read SITE2_DOMAIN
        if [ "$(isEmptyString "${SITE1_DOMAIN}")" = 'false' ] && [ "$(isEmptyString "${SITE2_DOMAIN}")" = 'false' ]
            then
            echo -e "${greenColour}===============================${endColour}"
            echo -e "\n\n${greenColour}---- NGINX FOR SITE1: ----${endColour}"
            $SED $arg0 "s/SITE1_DOMAIN/${SITE1_DOMAIN}/g" $NGINX/sites-enabled/SITE1
            echo -e "\n\n${greenColour}---- SITE1: ----${endColour}"
            $SED $arg0 "s/SITE1_DOMAIN/${SITE1_DOMAIN}/g" $DIR1/.env
            $SED $arg0 "s/SITE1_DOMAIN/${SITE1_DOMAIN}/g" $DIR2/.env
            echo -e "${greenColour}===============================${endColour}"
            echo -e "\n\n${greenColour}---- NGINX FOR SITE2: ----${endColour}"
            $SED $arg0 "s/SITE2_DOMAIN/${SITE2_DOMAIN}/g" $NGINX/sites-enabled/SITE2-api
            echo -e "\n\n${greenColour}---- SITE2: ----${endColour}"
            $SED $arg0 "s/SITE2_DOMAIN/${SITE2_DOMAIN}/g" $DIR1/.env
            $SED $arg0 "s/SITE2_DOMAIN/${SITE2_DOMAIN}/g" $DIR2/.env
            echo -e "${greenColour}===============================${endColour}"
        else
            echo -e "\n\n${redColour}[!][Error]: BAD DOMAIN NAME!!!${endColour}"
            exit 1
        fi
    done
}

#GIT FETCH TO REPOSITORY
gitClone

echo -e "${greenColour}===============================${endColour}"
echo -e "${greenColour}= Proceed with the setup? =${endColour}"

if pConfirm;
then
    gitPull
    setEnv
    setdomain
else
    ctrl_c
fi