#!/bin/bash

kb_script=$1
kb_author="Thomas Brettin"

tpage --define kb_script=$kb_script --define kb_author="$kb_author" script.tt  > $kb_script.pl
