
# Pre-requirements
- bash 4.0 (or higher)

# jenkins-plugin-count
Scans all config.xml files in $JENKINS_HOME/jobs/*/ and extracts plugins used. Generates CSV file with stats.
- The script scans Freestyle jobs by default. Other Job types can be configured (see `get-plugins.sh`), however, Plugin specific Pipeline steps or Pipelines in general are not scanned
- The rows of the CSV file contain the jobs.
- The columns contain the plugins.
- If a cell has a `1` inside, the job uses the corresponding plugin.
- The last row contains the number of times a plugin has been used across all jobs.

Set the correct Jenkins path and job type with the vars JENKINS_DIR and JOB_TYPE.
