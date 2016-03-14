#!/bin/bash

function checkSonarQubeServer() {
  error=1
  echo "Checking SonarQube Server..."
  curl --head --silent --verbose --connect-timeout 5 "$1" > data.txt 2> log.txt
  if [ "$?" = "0" ];
  then
    status=$(head -n 1 data.txt | awk '{print $2}')
    if [ "$status" = "200" ];
    then
      error=0
    else
      echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}). SonarQube Server is not available ($status)"
    fi
  else
    echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}). Could not connect to SonarQube Server: "
    cat log.txt
  fi
  rm data.txt
  rm log.txt
  return $error
}

function analyzeBranch() {
  checkSonarQubeServer "$1"
  if [ "$1" = "0" ];
  then
    if [ "$2" != "porcelain" ];
    then
      echo "Executing SonarQube analysis (${TRAVIS_BRANCH})..."
      # If SSL network failures happen, execute the analysis with -Djavax.net.debug=all
      mvn sonar:sonar -B -Dsonar.branch="$TRAVIS_BRANCH" -Dcoverage.reports.dir="$(pwd)/target/all" --settings config/src/main/resources/ci/settings.xml
    else
      echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}): Porcelain"
    fi
  fi
}
function skipBranchAnalysis() {
  echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}): Non Q.A. branch"
}

function skipPullRequestAnalysis() {
  echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}): Pull request"
}

function skipBuild() {
  echo "Skipping build..."
}

function skipSonarQubeAnalysis() {
  echo "Skipping SonarQube analysis..."
}

function runSonarQubeAnalysis() {
  if [ "${TRAVIS_PULL_REQUEST}" = "false" ];
  then
    case "${TRAVIS_BRANCH}" in
      master | develop ) analyzeBranch "$1" "$2";;
      feature\/*       ) analyzeBranch "$1" "$2";;
      *                ) skipBranchAnalysis ;;
    esac
  else
    skipPullRequestAnalysis
  fi
}

server=http://www.smartdeveloperhub.org/sonar/

case "${CI}" in
  skip      ) skipBuild ;;
  noqa      ) skipSonarQubeAnalysis ;;
  porcelain ) runSonarQubeAnalysis "$server" porcelain ;;
  *         ) runSonarQubeAnalysis "$server" "$1" ;;
esac
