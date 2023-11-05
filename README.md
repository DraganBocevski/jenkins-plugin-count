# jenkins-plugin-count
Scans all config.xml files in $JENKINS_HOME/jobs/*/ and extracts plugins used. Generates CSV file with stats.
- The rows of the CSV file contain the jobs.
- The columns contain the plugins.
- If a cell has a `1` inside, the job uses the corresponding plugin.
- The last row contains the number of times a plugin has been used across all jobs.

Set the correct Jenkins path and job type with the vars JENKINS_DIR and JOB_TYPE.
