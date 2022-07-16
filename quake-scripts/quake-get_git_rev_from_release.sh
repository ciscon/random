#!/bin/bash

rel=$1

git rev-list HEAD |tac|awk '{print NR  " " $s}'|grep ^$rel
