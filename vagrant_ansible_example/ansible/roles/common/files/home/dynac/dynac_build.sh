#/bin/bash
##############################################
#Description:
#  This script will setup a user's home dir and checkout
#  the Dynac NG and Dynac HA code and required projects in preparation of developing and building Dynac NG.
#Usage:
#  dynac_svn.sh username code_branch project


#Set script to debug mode
#set -x

#Setup variables:
#Install account - This takes into account the svn account as well.

function use_args() {

  usage="Run script as follows: dynac_build.sh username es_project ha_project"

  if [ "$#" -lt 3 ]
  then
    echo $usage
    exit 1
  else
    account=$1
    projname=$2
    ha_projname=$3
    echo "Building dynac for user: $1  Dynac ES  project: $2  Dynac HA project $3"
  fi

}

use_args $1 $2 $3 


#Preconfigure IP and hostname info in all of the required files.
h=$(hostname)
hs=$(hostname -s)
int=`/usr/sbin/ip route show | grep ^default | awk '{ print $5 }'`
ip=`/usr/sbin/ip addr | grep $int | grep -Eo '([0-9]*\.){3}[0-9]*' | head -n1`
syscfgfile="/home/$account/DynacNG/project/$projname/xml/system-Computer.syscfg.xml";

# configure system-Computer.syscfg.xml (basic config only)
grep $ip $syscfgfile || sed -i "/127\.0\.0\.1/i\    <ip-address\>$ip\<\/ip-address\>" $syscfgfile

# configure haManager.syscfg.xml
ha_project_xml="/home/$account/DynacHA/project/$ha_projname/xml"
echo "Updating project's $ha_project_xml/haManager.syscfg.xml file..."

#Edit the $HA_XML/haManager.syscfg.xml to include your hostname and ip
sed -i "/\<server name\=/c\\    <server name\=\"$h\" host\=\"$ip\" autoStart=\"false\"\/\>" $ha_project_xml/haManager.syscfg.xml

#Remove comments
sed -i "s/<\!-- <server/<server/"  $ha_project_xml/haManager.syscfg.xml
sed -i "s/false\"\/> -->/false\"\/>/" $ha_project_xml/haManager.syscfg.xml

#Setup the hosts file if it has not configured for this host.
grep $h /etc/hosts || echo "$ip     $h $hs" | sudo tee --append /etc/hosts

# Run HA Install
#This relies on the $PROJECT_NAME being set - see variable at the top
export PROJECT_NAME=$ha_projname
cd /home/$account/DynacHA/install 
sudo -E ./install NOREBOOT
#Everyone can write to /usr/local/java/tomcat/current directoryas z root :)
sudo chmod -R 777 /usr/local/java/tomcat/current

#Setup the source environment
/home/$account/DynacNG/buildenv/unix/setup/gen_src_env ~/DynacNG/buildenv/unix/

##################################
#Setup the OS environment
##################################

echo "Creating symlinks, setting up profiles, and copying binaries."

# create symbolic link and copy system-wide login script and other scripts
# ------------------------------------------------------------------------ 

sudo rm -f /usr/local/DynacNG
sudo ln -s /home/$account/DynacNG /usr/local/DynacNG

#Something weird with level of symlinks
rm -f /usr/local/DynacHA/project/current 
ln -s /home/$account/DynacHA/project/$ha_projname /usr/local/DynacHA/project/current

sudo cp /home/$account/DynacNG/setup/scripts/dynac.sh /etc/profile.d/
sudo cp /home/$account/DynacNG/setup/scripts/dynswitch /usr/local/bin
sudo cp /home/$account/DynacNG/setup/scripts/prjswitch /usr/local/bin 
sudo cp /home/$account/DynacNG/setup/scripts/hourlysar.sh /usr/local/bin
sudo chmod 0755 /usr/local/bin/dynswitch
sudo chmod 0755 /usr/local/bin/prjswitch
sudo chmod 0755 /usr/local/bin/hourlysar.sh

#Copy the jdbc properties file for this build
yes | cp /home/$account/DynacNG/buildenv/tools/jdbc/postgres-9.4/jdbc.properties /home/$account/DynacNG/project/$projname/config/


#Source the user's profile as well
source /home/$account/.bashrc
source /home/$account/.bash_profile

#Source the profiles you copied in the previous steps
. /etc/profile.d/dynac.sh
. /etc/profile.d/dynha.sh


#There is a haManager process that starts after the HA Manager is installed.
#It needs to be stopped and started to take the new config.
#The HA service apparently needs to be killed as stop does not stop it.
#I believe it is run from the install script.
sudo pkill -9 java 
echo "After killing Dynac processes:"
ps -ef | grep Dynac | grep -v grep
sleep 5
echo "Starting new haManager process..."
sudo service haManager start
sleep 5
#Start the build...
#bootstrap
/home/$account/DynacNG/setup/bootstrap
#dynset
source /home/$account/DynacNG/setup/setup
dynbuild -cdb
