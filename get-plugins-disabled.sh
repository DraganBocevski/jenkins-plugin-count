#!/bin/bash


#JENKINS_DIR=$JENKINS_HOME
JENKINS_DIR=$(pwd)
JOBS_DIR="$JENKINS_DIR/jobs"
JOB_TYPE="<project>"  # Deduced from the first line in config.xml. Freestyle job starts with <project>
OUTPUT_FILE="out.csv"

declare -A job_plugins # Plugins used in the job
declare -A all_plugins # Plugins used overall for all jobs 

count_jobs=0
count_disabled=0

# Get the plugin names per job
while IFS= read -r config; do
    #config_underscored=${config// /_}
    config_underscored=$config
    prefix_path="$JENKINS_DIR/jobs/"
    prefix_path_length=${#prefix_path}
    job_name=${config_underscored:prefix_path_length}
    job_name=$(echo "$job_name" | sed 's/\/jobs//g' | sed 's/config.xml//g')   
 
    #read -r first_line < "$config"
    #if [[ $first_line == "$JOB_TYPE"* ]]; then
    if grep -q "^$JOB_TYPE" "$config"; then
      ((count_jobs++))
      if grep -q "<disabled>true</disabled>" "$config"; then
        echo -e "\e[93mDisabled JOB  ...\e[0m        $job_name"
        ((count_disabled++))
      else
        echo -e "\e[92mProcessing JOB\e[0m...        $job_name"
        # We expect the config.xml in $JENKINS_DIR/jobs/job_name/config.xml
        # We substitute whitespaces in path with underscores. We remove the $JENKINS_DIR/jobs/ prefix from path
        job_name=${config_underscored:prefix_path_length}
        job_name=$(echo "$job_name" | sed 's/\/jobs//g')

        # Get all plugins for job
        # Example plugin lines in config.xml:
        # <hudson.plugins.jira.JiraProjectProperty plugin="jira@3.10">
        # <hudson.plugins.buildblocker.BuildBlockerProperty plugin="build-blocker-plugin@1.7.8">
        plugins=$(grep -oE 'plugin="[^"]+"' "$config" | cut -d '@' -f1 | cut -d '"' -f2 | sort | uniq | tr '\n' ' ')
    
        # Save plugins for the job as a space separated string like:
        # "artifactory git jira mailer"
        job_plugins["$job_name"]="$plugins"

        # Fill all_plugins array 
        # Keys: Plugin names
        # Values: Number of times a plugin in encountered across all jobs
        for plugin in $plugins; do
          ((all_plugins["$plugin"]++))
        done
      fi
    fi
done < <(find "$JOBS_DIR" -type f -name 'config.xml')

# We have the data. Now we create the CSV file and output to screen

# CSV header row (all_plugins keys)
echo -n "Job/Plugin," > $OUTPUT_FILE
printf "%s," "${!all_plugins[@]}" >> $OUTPUT_FILE
echo "CHECKSUM" >> $OUTPUT_FILE

# CSV rows - For each job (row), if a plugin (column) is used, we put 1, otherwise 0
for job in "${!job_plugins[@]}"; do
    echo -n "$job," >> $OUTPUT_FILE
    cksum=""
    for plugin in "${!all_plugins[@]}"; do
        if [[ "${job_plugins[$job]}" == *"$plugin"* ]]; then
            echo -n "1," >> $OUTPUT_FILE
            cksum+='1'
        else
            echo -n "0," >> $OUTPUT_FILE
            cksum+='0'
        fi
    done
    checksum=$(echo $cksum | sha1sum |  sed 's/ -//')
    echo $checksum >> $OUTPUT_FILE
done

# CSV last row - total count of plugin used across all jobs
echo -n "TOTALS," >> $OUTPUT_FILE
for plugin in "${!all_plugins[@]}"; do
  count="${all_plugins[$plugin]}"
  echo -n "$count," >> $OUTPUT_FILE
done

echo "" >> $OUTPUT_FILE


# Also output sorted list to screen for convenience
echo ""
printf "%5s  |  %s\n" "#" "Plugin Name"
echo "-------------------------------------------"
for key in "${!all_plugins[@]}"; do
    echo "$key ${all_plugins[$key]}"
done | sort -n -k2 | awk '{printf "%5s  |  %s\n", $2, $1}'
echo "-------------------------------------------"
echo "Plugins used across jobs. See $OUTPUT_FILE for details"
echo ""
echo -e "\e[92mTotal Jobs: $count_jobs\e[0m"
echo -e "\e[93mDisabled Jobs: $count_disabled\e[0m"
echo ""
