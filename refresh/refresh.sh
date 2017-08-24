#!/bin/bash

echo Paste the SSH link to the GHE repo.
read URL
echo Enter the templates to update from, seperated by spaces.
echo e.g. \`talk node\`. Put the type template first.
read TEMPLATES
echo Enter the cohort number e.g. \`020\`
read COHORT

NAME=`echo ${URL} | cut -d / -f2 | cut -d . -f1`
TYPE=`echo $TEMPLATES | cut -d ' ' -f1`
TECH=`echo $TEMPLATES | cut -d ' ' -f2`

cd ~/code/ga

if [ ! -d "$DIRECTORY" ]; then
  git clone ${URL}
fi

cd ${NAME}

git checkout -b ${COHORT}/master

git remote add ${TYPE}-template git@git.generalassemb.ly:ga-wdi-boston/${TYPE}-template.git
git fetch ${TYPE}-template

git remote add ${TECH}-template git@git.generalassemb.ly:ga-wdi-boston/${TECH}-template.git
git fetch ${TECH}-template

GI_COMMIT="Update \`.gitignore\` from templates
From \`${TYPE}-template\` and \`${TECH}-template\`
Refresh for cohort ${COHORT}"

git checkout ${TYPE}-template/master -- .gitignore
git diff --no-color --cached ${TECH}-template/master -- .gitignore|grep --color=never '^-[^-]'|cut -f 2- -d '-' >>.gitignore
git add .gitignore
git commit --allow-empty -m "${GI_COMMIT}"
