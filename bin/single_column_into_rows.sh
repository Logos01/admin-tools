#!/bin/bash
awk '{  
  if ($0 ~ /^$/ ) {
    printf("\n%s", $0)
  } else {
    printf("|%s", $0)
  }
}' $1
