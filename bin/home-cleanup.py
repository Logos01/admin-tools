#!/usr/bin/python
###############################################################################
#
# /usr/local/bin/home-cleanup.py
# - Archives invalid user home directories, deletes archives if not accessed
#   in more than two weeks.
# - Sets permissions in home directories to ensure users can access files
#   regardless of native ownership.
#
# Written 2012-10-15 by Logos01
#
###############################################################################


##-- CONFIGURATION --##

import sys, re
from optparse import OptionParser
from utils import shell
from datetime import datetime, timedelta


## Declares argument options.
parser=OptionParser()
parser.add_option("-d","--debug",action="store_true",dest="debug",help="show stderror and additional information")
parser.add_option("-v","--verbose",action="store_true",dest="verbose",help="show stdout",default=False)
parser.add_option("--dryrun",action="store_true",dest="dryrun",help="Dry run. Shows commands to be executed but does not actually perform them.",default=False)

(options, args) = parser.parse_args()



## Pre-declared variables.
home_directory_parameters = {}
two_weeks_ago = datetime.today() + timedelta(weeks=-2)

##--END CONFIGURATION --##

##-- FUNCTIONS/CLASSES --##

def print_output(output):
  if options.verbose: print "%s" % (output[0])
  if options.debug: print "%s" % (output[1])

def get_unowned_home_directories():
  find_cmd = 'find /home -mindepth 1 -maxdepth 1 -type d -nouser'
  output = shell(find_cmd,noerr=False).run()
  print_output(output)
  return output[0]

def get_valid_home_directories():
  find_cmd = 'find /home -mindepth 1 -maxdepth 1 -type d ! -nouser'
  output = shell(find_cmd,noerr=False).run()
  print_output(output)
  return output[0]

def ownership_values(home_directory):
  search_cmd = 'ldapsearch -x homeDirectory=' + home_directory + " homeDirectory unixuid gidNumber | awk '/homeDirectory|uid|gidNumber/ && !/=|requesting|filter/ {print $2}'"
  output = shell(search_cmd,noerr=False,shell=True).run()
  print_output(output)
  return output[0]

def capture_return_status(cmd):
  cmd = cmd + "; echo $?"
  output = shell(cmd,noerr=False,shell=True).run()
  print_output(output)
  exit_status = output[0][-1]
  return exit_status

def handle_failure(command,captured_status):
  if captured_status != "0":
    message = command + "returned exit status: " + captured_status + ".  Exiting."
    sys.exit(message)

def run_commands(*commands):
  for cmd in commands:
    if options.dryrun or options.debug or options.verbose:
      print "%s" % (cmd)
    if not options.dryrun:
      ret = capture_return_status(cmd)
      if options.debug or options.verbose: print "%s" % (ret)
      handle_failure(cmd,ret)

def correct_home_directory_ownership(key,values):
  (homeDir, uid, gid) = values
  setfacl_cmd = "setfacl -R -d -m u:" + uid + ":rwx " + key
  chown_cmd = "chown -R " + uid + "." + gid + " " + key
  run_commands(setfacl_cmd,chown_cmd)

def age_of(tarball):
  rawstat_cmd = 'stat -c %z ' + tarball
  rawstat = shell(rawstat_cmd,noerr=False).run()
  print_output(rawstat)
  rawstat = rawstat[0]
  calendar_date = rawstat[0].split(' ')[0]
  parsed_date = calendar_date.split('-')
  for i in range(len(parsed_date)):
    parsed_date[i] = int(parsed_date[i])
  output = datetime(parsed_date[0],parsed_date[1],parsed_date[2])
  return output

def find_tarballs():
  tarball_search_cmd = 'find /home -maxdepth 1 -mindepth 1 -type f -name "*.tgz"'
  output = shell(tarball_search_cmd,noerr=False).run()
  print_output(output)
  return output[0]

##-- END FUNCTIONS/CLASSES --##

##----   RUNTIME    ----##


for home_directory in get_valid_home_directories():
  home_directory_parameters[home_directory] = ownership_values(home_directory)

for key,values in home_directory_parameters.items():
  if len(values): correct_home_directory_ownership(key,values)

for unowned_directory in get_unowned_home_directories():
  if len(unowned_directory) and not re.search('quota',unowned_directory):
    tar_cmd = 'tar czf ' + unowned_directory +".tgz " + unowned_directory
    del_cmd = 'rm -rf ' + unowned_directory
    run_commands(tar_cmd,del_cmd)

for tarball in find_tarballs():
  if age_of(tarball) > two_weeks_ago:
    del_cmd = 'rm -f ' + tarball
    run_commands(del_cmd)

##---- END RUNTIME  ----##
