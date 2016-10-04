#/bin/bash
# {{ ansible_managed }}
##############################################
#Description:
#  This script will setup a user's home dir and checkout 
#  the Dynac NG and Dynac HA code and required projects in preparation of developing and building Dynac NG. 
#Usage:
#  dynac_svn.sh username code_branch dynac_project dynac_ha_project  


#Set script to debug mode
#set -x

#Setup variables:
#Install account - This takes into account the svn account as well.

function use_args() {

  usage="Run script as follows: dynac_svn.sh username dynac_branch dynac_project dynac_ha_project svn_server.\nsvn_server is an optional parameter."
 
  if [ "$#" -lt 4 ]
  then
    echo $usage
    exit 1
  else
    account=$1
    svnbranch=$2
    projname=$3
    ha_projname=$4
    echo "Preparing environment for user: $1 svn branch: $2 dynac project: $3 dynac ha project: $4"
  fi 

  if [ "$5" != "" ]
  then
    svn_server=$5
  else
    svn_server=svn.transdyn.com
    echo "Setting svn server to: svn.transdyn.com"
    echo "Note: To set svn server use these options:"
    echo "dynac_svn.sh username code_branch project svn_server"
  fi

}

use_args $1 $2 $3 $4

#Pulling a specific branch is possible...

installdate=`date +"%m-%d-%y"`

########################
#Prep work
########################

#Auto accept the HostKey...
ssh -oStrictHostKeyChecking=no $svn_server "echo Auto accepting hostkey for svn server."
##########################
#DYNAC-NG
##########################

echo "Checking out Dynac-NG branch: $svnbranch"

#Clean up previous installation
mv /home/$account/DynacNG /home/$account/oldDynacNG.$installdate
mkdir /home/$account/DynacNG
sudo chown $account:$account /home/$account/DynacNG
cd /home/$account/DynacNG

#If you are pulling from the trunk:

if [ "$svnbranch" != "v14trunk" ]
then
  echo "Pulling specific branch..."
  #If you are pulling a specific branch:
  svn checkout svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/branches/$svnbranch/buildenv svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/branches/$svnbranch/setup svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/branches/$svnbranch/run svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/branches/$svnbranch/project
else
  echo "Pulling from trunk..."
  svn checkout svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/v14trunk/buildenv svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/v14trunk/setup svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/v14trunk/run svn+ssh://svn.transdyn.com/work/databases/svn/DynacES/v14trunk/project
fi

#Pull the project:
svn checkout svn+ssh://svn.transdyn.com/work/databases/svn/project/trunk/$projname project/$projname

#Set permissions on everything you just downloaded for DYNACNG
sudo chown -R $account:$account /home/$account/DynacNG

#Setup the source environment
/home/$account/DynacNG/buildenv/unix/setup/gen_src_env /home/$account/DynacNG/buildenv/unix/

##########################
#DYNAC-HA
##########################

ha_branch=`grep "^HA|" /home/$account/DynacNG/setup/install/config/dynac-util.txt | awk -F'|' '{print $2 }'`

echo "Starting Dynac-HA installation for branch: $ha_branch"

#Setup the directories
echo "Setting up the directories and permissions..."
yes | mv /home/$account/DynacHA /home/$account/oldDynacHA.$installdate

mkdir /home/$account/DynacHA
sudo chown $account:$account  /home/$account/DynacHA
cd /home/$account/DynacHA


#Check out the branch of Dynac HA specified in the dynac-util.txt file.
svn checkout svn+ssh://svn.transdyn.com/work/databases/svn/DynacHA/branches/$ha_branch .
#Checkout the project you have specified
svn checkout svn+ssh://svn.transdyn.com/work/databases/svn/haproject/trunk/$ha_projname project/$ha_projname

sudo chown -R $account:$account /home/$account/DynacHA
