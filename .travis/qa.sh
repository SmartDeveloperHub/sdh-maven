#!/bin/bash

function analyzeBranch() {
  if [ "$2" != "porcelain" ];
  then
    echo "Checking SonarQube Server..."
    curl --head "$1" > /dev/null 2>&1
    if [ "$?" = "0" ];
    then
      echo "Executing SonarQube analysis (${TRAVIS_BRANCH})..."
      # If SSL network failures happen, execute the analysis with -Djavax.net.debug=all
      mvn sonar:sonar -B -Dsonar.branch=$TRAVIS_BRANCH -Dcoverage.reports.dir=$(pwd)/target/all --settings config/src/main/resources/ci/settings.xml
    else
      echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}): Cannot connect to SonarQube Server ($1)"
    fi
  else
    echo "Skipped SonarQube analysis (${TRAVIS_BRANCH}): Porcelain"
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
      feature\/*       ) analyzeBranch "$2" "$2";;
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
