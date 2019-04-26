#!/bin/bash
# Copyright (C) 2019 PizzaFactory Project
# Lisesed under EPL-2.0.

PRIVATE_REPO=${PRIVATE_REPO:-}
ORGANIZATION=athrill

cat <<__HEADER
# This file was auto-generated.

trigger:
  branches:
   include:
     - master

jobs:

__HEADER

for dockerfile in $(find recipes -follow -name 'Dockerfile'); do
    a=${dockerfile%/Dockerfile}
    b=${a#recipes/}
    tag="${ORGANIZATION}/${b/\//:}"
    from_all=$(sed -ne 's/FROM[ \t]\{1,\}\([^ \t]\{1,\}\)[ \t]\{1,\}as.*/\1/p' $dockerfile)
    from_a=$(sed -ne 's/^FROM *\(.*\)/\1/p' $dockerfile | tail -1)
    from=${from_a///}
    from_path_a=${from//:/\/}
    from_path=${from_path_a/${ORGANIZATION}/recipes}

    cat <<__BODY1

### $dockerfile $tag depends on $from $from_path
  - job: "${dockerfile//[-\/\.]/__}"
    timeoutInMinutes: 0
    pool:
      vmImage: 'Ubuntu 16.04'
__BODY1
if [[ -e $from_path ]]; then
    cat <<__BODY2
    dependsOn: "${from_path//[-\/\.]/__}__Dockerfile"
__BODY2
fi
if [[ $PRIVATE_REPO != "" ]]; then
  pushtag=$PRIVATE_REPO/$tag
  fromtag=$PRIVATE_REPO/$from
else
  pushtag=$tag
  fromtag=$from
fi
cat <<__HEAD
    steps:

    - task: Docker@1
      displayName: 'Login to ACR.'
      inputs:
        command: login
        dockerRegistryEndpoint: camino.azurecr.io
        containerregistrytype: Container Registry

    - script: |
        set +e
__HEAD
for i in $from_all; do
if [[ $PRIVATE_REPO != "" ]]; then
  partial_from=$PRIVATE_REPO/$i
else
  partial_from=$i
fi
cat <<__PARTIAL
        docker pull $partial_from
        if [[ \$? == 0 ]]; then
          docker tag $partial_from $i
        fi
__PARTIAL
done
cat <<__BODY
        docker pull $pushtag
        if [[ \$? == 0 ]]; then
          docker tag $pushtag $tag
        else
          docker pull $tag
        fi
        if [[ \$? != 0 ]]; then
          docker tag scratch $tag
        fi
        docker pull $fromtag
        if [[ \$? == 0 ]]; then
          docker tag $fromtag $from
        else
          docker pull $from
        fi
        if [[ \$? != 0 ]]; then
          docker tag scratch $from
        fi
        exit 0
      continueOnError: true
      failOnStderr: false
      displayName: "Pulling cache. (errors will be ignored)"
    - script: docker build -f $dockerfile --cache-from $tag -t $pushtag ${dockerfile%/*}
      displayName: "Building $pushtag"
    - script: docker push $pushtag
      displayName: "Pushing $pushtag"
      condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
__BODY
done
