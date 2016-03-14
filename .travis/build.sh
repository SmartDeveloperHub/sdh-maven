#!/bin/bash
set -e

function deploy() {
  if [ "$1" != "porcelain" ];
  then
    echo "Executing Maven deploy (${TRAVIS_BRANCH})..."
    mvn clean deploy -B -Dcodebase.directory=$(pwd) -Dcoverage.reports.dir=$(pwd)/target/all --settings config/src/main/resources/ci/settings.xml
  else
    echo "Skipped Maven deploy (${TRAVIS_BRANCH}): Porcelain"
  fi
}

function install() {
  if [ "$1" != "porcelain" ];
  then
    echo "Executing Maven install (${TRAVIS_BRANCH})..."
    mvn clean install -B -Dcoverage.reports.dir=$(pwd)/target/all --settings config/src/main/resources/ci/settings.xml
  else
    echo "Skipped Maven install (${TRAVIS_BRANCH}): Porcelain"
  fi
}

if [ "${CI}" = "skip" ];
then
  echo "Skipping build..."
  exit $?
fi

mode=$1
if [ "$mode" != "porcelain" ];
then
  mode=${CI}
fi

if [ "${TRAVIS_PULL_REQUEST}" = "false" ];
then
  case "${TRAVIS_BRANCH}" in
    master | develop ) deploy "$mode";;
    feature\/*       ) install "$mode";;
    *                ) install "$mode";;
  esac
else
  install "$mode"
fi
