#! /bin/bash

export TOKEN=${1:-"youruser:yourtoken"}
JENKINS_URL=http://localhost:8080

JOBS_DIR=jobs
GEN_DIR=gen
TEMPLATE_DIR=templates
FS_JOBS_TO_CONVERT=FSjobsToConvert.txt

mkdir -p $GEN_DIR
rm -Rf $GEN_DIR/*

#read jobs from file
FS_JOBS=$(cat $FS_JOBS_TO_CONVERT)
for JOB_NAME in $FS_JOBS
do
    echo -e "##############################\n"
    #JOB_NAME=$(dirname $JOB_NAME)/$(basename $JOB_NAME)
    echo -e "$JOB_NAME\n"

    mkdir -p $GEN_DIR/$JOB_NAME

    echo "Call the convert function for job:$JOB_NAME"
    curl  -s -u $TOKEN  "$JENKINS_URL/job/$JOB_NAME/todeclarative/" \
      -o $GEN_DIR/$JOB_NAME/resultPipeline.html
    #echo "created: $GEN_DIR/$JOB_NAME/resultPipeline.html"

    echo "Extract Pipeline from html result page"
    export PIPELINE=$(xmllint --html \
     --xpath 'string(//textarea[@id="jenkinsfile-content"]/text())' \
      $GEN_DIR/$JOB_NAME/resultPipeline.html 2>/dev/null)

    envsubst < $TEMPLATE_DIR/Jenkinsfile > $GEN_DIR/$JOB_NAME/Jenkinsfile.groovy

    #echo "Create new Job config.xml file local from template. The new Pipeline from the converter will be used"
    envsubst < $TEMPLATE_DIR/newJob-config-template.xml >  $GEN_DIR/$JOB_NAME/config.xml

    #If job is in a folder, we need to calculate the sub path
    JOB_PATH=""
    JOB_NAME_ORG=$JOB_NAME
    if [[ -n $(echo $JOB_NAME |grep -o "/job/") ]]; then
        #see https://gist.github.com/stuart-warren/7786892
        #https://learnbyexample.github.io/cli_text_processing_coreutils/basename-dirname.html
        #echo "IS IN FOLDER $JOB_NAME"
        JOB_PATH="$JOB_NAME/"
        JOB_PATH=$(echo $JOB_PATH |sed "s#/job/#/#g" | sed "s#/.*/##g" )
        JOB_PATH="job/${JOB_PATH}/"
        JOB_NAME=$(basename "$JOB_NAME")
    fi

    echo "Create a new Pipeline Job: ${JOB_NAME}-PIPELINE from $GEN_DIR/$JOB_NAME_ORG/config.xml"
    #Remove the comment to enable
    #curl -L -s -u $TOKEN  -XPOST  "$JENKINS_URL/${JOB_PATH}createItem?name=${JOB_NAME}-PIPELINE" --data-binary @$GEN_DIR/$JOB_NAME_ORG/config.xml -H "Content-Type:text/xml"
    echo "curl -L -s -u $TOKEN  -XPOST  $JENKINS_URL/${JOB_PATH}createItem?name=${JOB_NAME}-PIPELINE  --data-binary @$GEN_DIR/$JOB_NAME_ORG/config.xml"

done

echo -e "############################## CHECK FOR MISSING EXTENSIONS\n"
#cat $GEN_DIR/*.groovy |grep "No converter for Builder:.*$"  | sort | uniq
cd $GEN_DIR
echo -e "## LIST OF ALL MISSING CONVERTER EXTENSIONS"
grep -iHro "No converter for.*$" | sort | uniq | grep -v -e  "^.*config.xml.*$" -e  "^.*html.*$"
#cat $GEN_DIR/*.xml |grep -E -o "No converter for.*$" |sort |uniq
echo -e "## COUNT FOR MISSING CONVERTER EXTENSIONS"
find . -name "*.groovy" | grep -iHro "No converter for.*$" | grep -v -e  "^.*config.xml.*$" -e  "^.*html.*$" |  grep -o ":.*$" |  sort |  uniq -c
cd -
