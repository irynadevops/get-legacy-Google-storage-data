#!/bin/bash

#######################################
# Function convert date to UTC format #
#######################################

date_convert_to_UTC () {
  date --utc --date "$1" +%s
}

#####################################################
# Calculates the difference in seconds,  minutes,   #
# hours, or days between two dates.                 #
# By default, the difference is calculated in days. #
#####################################################

date_difference () {
  case $1 in
      -s)   sec=1;      shift;;
      -m)   sec=60;     shift;;
      -h)   sec=3600;   shift;;
      -d)   sec=86400;  shift;;
      *)    sec=86400;;
  esac
  date1=$(date_convert_to_UTC $1)
  date2=$(date_convert_to_UTC $2)
  diff_sec=$((date2-date1))
  if ((diff_sec < 0))
  then 
    abs=-1; else abs=1;
  fi
  echo $((diff_sec/sec*abs))
}


###########################################################################################
# The function runs through all Google buckets and compares the update time  of each file #
# with the current date and finds the difference in days (seconds, minutes, hours)        #
# and displays the file name and the difference if such files are found.                  #
###########################################################################################

find_latency_data_in_all_GCP_buckets () {

## Get all GCP bucket names
for storage_name in `gsutil ls | cut -d'/' -f3`
  do

  ## Create a temporary file with the update time of each file in the current explored bucket 
  gsutil ls -Lr "gs://${storage_name}" | grep "Update time" | cut -d" " -f19,20,21 >date_of_update.txt

  ## Create a temporary file with the all file names in the current explored bucket
  gsutil ls -Lr "gs://${storage_name}" | grep "Update time" -B 2 | grep "gs://" >file_names.txt

  ## Check taht temporary files are not empty
  if [[ -s date_of_update.txt || -s file_names.txt ]]
  then
    while read line
    do
      read -r file1 <&3
      read -r file2 <&4
      ## Find the difference in days (can be selected, see the description of the "data difference" function) between the current date and the update time of each file
      if [ $(date_difference -d "$(date -d "${file1}" +"%Y-%m-%d")" "$(date +"%Y-%m-%d")") -gt 180 ]
      then
        ## Change if you select another option(hour,minute,second) to find difference
        echo "Data ${file2} is updated more then 6 month ago"; 
      fi
    done<date_of_update.txt 3<date_of_update.txt 4<file_names.txt
  fi
done

## Delete temporary files
rm date_of_update.txt
rm bucket_names.txt
}

find_latency_data_in_all_GCP_buckets
