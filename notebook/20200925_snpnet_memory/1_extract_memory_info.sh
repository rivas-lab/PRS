#!/bin/bash
set -beEuo pipefail

log_f=$1

egrep 'ever-active variables|variables in the strong set|Iteration|gc trigger|Ncells|Vcells' ${log_f}
