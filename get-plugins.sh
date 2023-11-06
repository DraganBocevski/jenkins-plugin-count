#!/bin/bash

#JENKINS_DIR=$JENKINS_HOME
JENKINS_DIR=$(pwd)
JOBS_DIR="$JENKINS_DIR/jobs"
JOB_TYPE="<project>"  # Deduced from the first line in config.xml. Freestyle job starts with <project>
OUTPUT_FILE="out.csv"

declare -A job_plugins # Plugins used in the job
declare -A all_plugins # Plugins used overall for all jobs 

# Get the plugin names per job
for config in $(find $JOBS_DIR -type f -name config.xml); do   
    read -r first_line < "$config"
    if [[ $first_line == "$JOB_TYPE"* ]]
    then
      # We expect the config.xml in $JENKINS_HOME/jobs/job_name/config.xml
      job_name=$(basename $(dirname $config))

      # Get all plugins for job
      # Example plugin lines in config.xml:
      # <hudson.plugins.jira.JiraProjectProperty plugin="jira@3.10">
      # <hudson.plugins.buildblocker.BuildBlockerProperty plugin="build-blocker-plugin@1.7.8">
      plugins=$(grep -oE 'plugin="[^"]+"' $config | cut -d '@' -f1 | cut -d '"' -f2 | sort | uniq | tr '\n' ' ')
    
      # Save plugins for the job as a space separated string like:
      # "artifactory git jira mailer"
      job_plugins["$job_name"]="$plugins"

      # Fill all_plugins array 
      # Keys: Plugin names
      # Values: Number of times a plugin in encountered across all jobs
      for plugin in $plugins; do
        if [ -v all_plugins["$plugin"] ]
          then
            ((all_plugins["$plugin"]++))
          else
            all_plugins["$plugin"]=1
          fi
      done
    fi
done


# We have the data. Now we create the CSV file and output to screen

# CSV header row (all_plugins keys)
echo -n "Job/Plugin," > $OUTPUT_FILE
printf "%s," "${!all_plugins[@]}" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# CSV rows - For each job (row), if a plugin (column) is used, we put 1, otherwise 0
for job in "${!job_plugins[@]}"; do
    echo -n "$job," >> $OUTPUT_FILE
    for plugin in "${!all_plugins[@]}"; do
        if [[ "${job_plugins[$job]}" == *"$plugin"* ]]; then
            echo -n "1," >> $OUTPUT_FILE
        else
            echo -n "0," >> $OUTPUT_FILE
        fi
    done
    echo "" >> $OUTPUT_FILE
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
printf "%5s  |  %s\n" "Used" "Plugin Name"
echo "-------------------------------------------"
for key in "${!all_plugins[@]}"; do
    echo "$key ${all_plugins[$key]}"
done | sort -n -k2 | awk '{printf "%5s  |  %s\n", $2, $1}'
echo "-------------------------------------------"
echo "Plugins used across jobs. See $OUTPUT_FILE for details"
echo ""
