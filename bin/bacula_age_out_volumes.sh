#!/bin/bash
##-- CONFIGURATION --##

Ago=' days ago'
Incr='2'
Diff='7'
Full='31'
Base='365'

##-- END CONFIGURATION --##

##-- FUNCTIONS --##
#Date Preparation
#-
Y(){ date -d"$1" +%Y; }
M(){ date -d"$1" +%m | sed 's/^0//' ; }
D(){ date -d"$1" +%d | sed 's/^0//' ; }
#-

set_toprune(){
  toprune=($(ls | grep $1 | grep $2))
  for x in ${toprune[@]};
    do jobs=("${jobs[@]}" "$(echo $x | awk -F'--' '{print $3}')" )
  done
}

cleandir_Incremental(){
  set_toprune $Incremental_prunedate "Incremental"

  if [[ "${toprune[@]}" =~ "Incremental" ]] ; then
    ( for x in ${jobs[@]} ; do 
        echo "delete jobid=$x yes";
      done;
      for x in ${toprune[@]} ; do 
        echo "delete volume=$x yes" ;
      done\
    ) | bconsole
  
    for x in ${toprune[@]} ; do
      rm $x
    done
  fi
  unset jobs
}

cleandir_Differential(){
  set_toprune $Differential_prunedate "Differential"

  if [[ "${toprune[@]}" =~ "Differential" ]] ; then
    ( for x in ${jobs[@]} ; do 
        echo "delete jobid=$x yes";
      done;
      for x in ${toprune[@]} ; do 
        echo "delete volume=$x yes" ;
      done\
    ) | bconsole
  
    for x in ${toprune[@]} ; do
      rm $x
    done
  fi
  unset jobs
}


cleandir_Full(){
  set_toprune $Full_prunedate "Full"

  if [[ "${toprune[@]}" =~ "Full" ]] ; then
    ( for x in ${jobs[@]} ; do 
        echo "delete jobid=$x yes";
      done;
      for x in ${toprune[@]} ; do 
        echo "delete volume=$x yes" ;
      done\
    ) | bconsole
  
    for x in ${toprune[@]} ; do
      rm $x
    done
  fi
  unset jobs
}

cleandir_Base(){
  set_toprune $Base_prunedate "Base"

  if [[ "${toprune[@]}" =~ "Base" ]] ; then
    ( for x in ${jobs[@]} ; do 
        echo "delete jobid=$x yes";
      done;
      for x in ${toprune[@]} ; do 
        echo "delete volume=$x yes" ;
      done\
    ) | bconsole
  
    for x in ${toprune[@]} ; do
      rm $x
    done
  fi
  unset jobs
}

##-- END FUNCTIONS --##

##-- RUNTIME --##

Incremental_prunedate="$(Y "${Incr}${Ago}")-$(M "${Incr}${Ago}")-$(D "${Incr}${Ago}")" 
Differential_prunedate="$(Y "${Diff}${Ago}")-$(M "${Diff}${Ago}")-$(D "${Diff}${Ago}")" 
Full_prunedate="$(Y "${Full}${Ago}")-$(M "${Full}${Ago}")-$(D "${Full}${Ago}")"
Base_prunedate="$(Y "${Base}${Ago}")-$(M "${Base}${Ago}")-$(D "${Base}${Ago}")"

client_dirs=($(ls /zraid0/backups))

for dir in ${client_dirs[@]}; do
  cd /zraid0/backups/$dir
  [[ "$(ls | awk "/Differential/ && /$Incremental_prunedate/")" =~ "Differential" ]] && cleandir_Incremental
  cleandir_Differential
  cleandir_Full
  cleandir_Base
done

##-- END RUNTIME --##
