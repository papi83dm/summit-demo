#!/bin/bash

stack=$1
echo -ne `heat output-show $stack key`|tr -d "\""
