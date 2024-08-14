#!/bin/bash -f
: 'A script that backs up important files. 
Backups are archived and compressed. Dates are part of the name 
archives. 
The list of files is set via a variable, with the possibility of redefinition
via script launch arguments. The default value of /etc. 
• it is possible to exclude/include files by mask: *.txt, *.jpg, etc. 
• there is a built-in script for cleaning backups according to a schedule. 
• there are options for: backup location folders, 
notifications, compression ratio.'
#echo $$

function arch_backup() {
  TC="tar -Ocv" # TC - tar command
  if [[ -z "$InputDir" ]]; then
	 InputDir=/etc
  fi
  FD="find $InputDir" # FD - find command
  if [[ -z "$Search_Depth" ]]; then
	 MD="-maxdepth 1" # MD - maxdepth arg
  else
     MD="-maxdepth $Search_Depth"
  fi
  FD="$FD $MD"
  if [[ -n "$CertainFilesPat" ]]; then
	 CertainFilesPat=${CertainFilesPat// / -o -name }
	 CertainFilesPat=${CertainFilesPat/# -o -name /-name }
	 FD="$FD $CertainFilesPat"
  fi
  FD="$FD -type f"
  if [[ -z "$OutputDir" ]]; then
	 OutputDir=/home
  fi
  if [[ -z "$Retention" ]]; then
	 Retention=w
  fi
  if [[ -z "$Compression_level" ]]; then
	 Compression_level=6
  fi
  if [[ -n "$ExclPat" ]]; then
	 ExclPat=${ExclPat// / --exclude=}
	 TC=${TC/tar -Ocv/tar -Ocv"$ExclPat"}
  fi
  
   sudo $FD | sudo xargs $TC | gzip -"$Compression_level"c | sudo tee "$OutputDir"/backup_"$Retention"_"$(date +%Y-%m-%d)".tgz > /dev/null
  
  sudo mkdir /var/log/My_backuper 2> /dev/null
  if [[ -z $(sudo cat /var/log/My_backuper/My_backuped_files.txt 2> /dev/null | sudo grep "$OutputDir"/backup_"$Retention"_"$(date +%Y-%m-%d).tgz") ]]; then
     sudo printf "\n$OutputDir"/backup_"$Retention"_"$(date +%Y-%m-%d).tgz\n" | sudo tee -a /var/log/My_backuper/My_backuped_files.txt > /dev/null
  fi
  exit 1
}

function delete_old_backups () {
echo -n | sudo tee /var/log/My_backuper/My_backuped_deleted_files.txt > /dev/null
while IFS= read -r line
do
  [[ -z "$line" ]] && continue
  if echo "$line" | grep "_d_" 1> /dev/null && find "$line" -mtime +1 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then
	    if [[ "$User_name" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "$User_name" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_w_" 1> /dev/null && find "$line" -mtime +7 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then 
	    if [[ "$User_name" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "$User_name" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_m_" 1> /dev/null && find "$line" -mtime +31 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then    
	    if [[ "$User_name" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "$User_name" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_y_" 1> /dev/null && find "$line" -mtime +365 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then     
	    if [[ "$User_name" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "$User_name" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi  
done < /var/log/My_backuper/My_backuped_files.txt
Diff=$(comm -13 <(sort -u /var/log/My_backuper/My_backuped_deleted_files.txt) <(sort -u /var/log/My_backuper/My_backuped_files.txt))
printf "$Diff\n" | sudo tee /var/log/My_backuper/My_backuped_files.txt > /dev/null
exit 1
}

function create_backup_delete_script () {
printf "$User_name" | sudo tee /var/log/My_backuper/User_to_notice.txt > /dev/null
echo '#!/bin/bash -f

echo -n | sudo tee /var/log/My_backuper/My_backuped_deleted_files.txt > /dev/null
while IFS= read -r line
do
  [[ -z "$line" ]] && continue
  if echo "$line" | grep "_d_" 1> /dev/null && find "$line" -mtime +1 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then
	    if [[ "cat /var/log/My_backuper/User_to_notice.txt" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "`cat /var/log/My_backuper/User_to_notice.txt`" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_w_" 1> /dev/null && find "$line" -mtime +7 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then 
	    if [[ "cat /var/log/My_backuper/User_to_notice.txt" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "`cat /var/log/My_backuper/User_to_notice.txt`" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_m_" 1> /dev/null && find "$line" -mtime +31 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then    
	    if [[ "cat /var/log/My_backuper/User_to_notice.txt" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "`cat /var/log/My_backuper/User_to_notice.txt`" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi
  if echo "$line" | grep "_y_" 1> /dev/null && find "$line" -mtime +365 | sudo xargs rm 2> /dev/null && echo "$line" | sudo tee -a /var/log/My_backuper/My_backuped_deleted_files.txt; then     
	    if [[ "cat /var/log/My_backuper/User_to_notice.txt" ]]; then
		   sudo DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" -u "`cat /var/log/My_backuper/User_to_notice.txt`" notify-send -t 30000 Flushed "$line""	"-"	"deleted
	    fi	
  fi  
done < /var/log/My_backuper/My_backuped_files.txt
Diff=$(comm -13 <(sort -u /var/log/My_backuper/My_backuped_deleted_files.txt) <(sort -u /var/log/My_backuper/My_backuped_files.txt))
printf "$Diff\n" | sudo tee /var/log/My_backuper/My_backuped_files.txt > /dev/null
exit 1
' | sudo tee /var/log/My_backuper/backup_delete_script.sh > /dev/null

sudo chmod +x /var/log/My_backuper/backup_delete_script.sh

echo '[Unit]
Description=Delete backups script
 
[Service]
ExecStart=/var/log/My_backuper/backup_delete_script.sh
Type=simple
' | sudo tee /lib/systemd/system/delete_backups.service > /dev/null

echo '[Unit]
Description=timer for backup_delete_script
 
[Timer]
OnCalendar=*-*-* 12:00:00
 
[Install]
WantedBy=timers.target
' | sudo tee /lib/systemd/system/delete_backups.timer > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable delete_backups.timer
sudo systemctl start delete_backups.timer

exit 1
}

function help() {
printf 'Makes backups of selected files, should be executed with -f bash option
Usage: cmd [-i] [input directory] [-o] [output directory] [-r] [retention: dwmy allowed, w - default]
	   [-d] [search depth: 123... 1 - default] [-e] [exclude "pattern", multiple [-e] allowed ]
	   [-c] [certain files "pattern", multiple [-c] allowed] [-f] [flush old backups based on retain:
	         user name agr to be notified after backup deleted,  used separately]
	   [-s] [create script to automate backup deleting process, user name agr to be notified after
			 backup deleted, used separately]
	   [-z] [compression level: 1-9, 6 by default] 
	   /var/log/My_backuper/My_backuped_files.txt - current backups
	   /var/log/My_backuper/My_backuped_deleted_files.txt - last deleted backups
	   /var/log/My_backuper/backup_delete_script.sh - backups deliting script
	
 '
exit 1
}

while getopts ":hs:f:d:i:o:r:e:c:z:" opt; do
  case ${opt} in
  i)
    InputDir=$OPTARG
    ;;
  o)
    OutputDir=$OPTARG
    ;;
  r)
    case $OPTARG in
	d)
	  Retention=$OPTARG
	  ;;
	w)
	  Retention=$OPTARG
	  ;;
	m)
	  Retention=$OPTARG
	  ;;
	y)
	  Retention=$OPTARG
	  ;;
	esac	
	if [[ -z $(echo $Retention | grep "^d$\|^w$\|^m$\|^y$") ]]; then
	   echo '-r [dwmy]: retention arg should be (day, week, month, year), default value will be used'
    fi
	;;
  d)
	Search_Depth=$OPTARG
	;;
  e)
	ExclPat="$ExclPat $OPTARG"
	;;
  c)
	CertainFilesPat="$CertainFilesPat $OPTARG"
	;;
  f)
	User_name=${OPTARG:-""}
    delete_old_backups $User_name
    ;; 
  s)
	User_name=$OPTARG   
    create_backup_delete_script $User_name
    ;;
  z)
    if ((1<=OPTARG && OPTARG<=9)); then
	   Compression_level=$OPTARG
	else
	   echo "[1-9]: compression level arg should be"
	fi
    ;;
  h)
    help
    ;;
  :)
    echo "Invalid option, maybe provide \"\" if empty: $OPTARG requires an argument" 1>&2
	exit 1
    ;;
  \?)
    echo "Invalid option: $OPTARG" 1>&2
	exit 1
    ;;
  esac
done
shift $((OPTIND-1))
arch_backup $InputDir $OutputDir $Retention $Search_Depth $ExclPat $CertainFilesPat $Compression_level