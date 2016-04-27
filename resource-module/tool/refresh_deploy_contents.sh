#!/bin/bash

cd `dirname ${BASH_SOURCE[0]}`/../deploy
(
    echo "heat_template_version: 2013-05-23"
    echo "outputs:"
    echo "  contents:"
    echo "    description: deploy contents"
    echo "    value: |"
    find * | sort | cpio -oc | gzip -9 -n | base64 | while read line; do
        echo "      $line";
    done
) > ../heat/deploy_contents.yaml
cd ../heat


