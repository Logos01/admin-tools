"""
Useful functions for admin scripting.
Class: shell(self,*args,**options)
"""
import shlex, subprocess, re, os, time, datetime
from subprocess import Popen, PIPE, call
import StringIO

class shell:
  def __init__(self,*args,**options):
    """
    shell(command_string,[key=value,[key=value]]).run()
      Executes the command in a subprocess shell.
      noerr - toggle suppression of stderr (default True)
      shell - toggle creation of genuine tty (default False)
      Takes standard subprocess.Popen args. stdout=PIPE,stderr=PIPE already set.
    shell(['some','iterable','object']).iters()
      Returns the length of the iterable object.
    shell(['some','arbitrary','set','of','values']).dedup()
      Returns in list form only the unique values in the input.
    shell(string,command,key=value).send()
      Passes 'string' as stdin of 'command'
      I.e.;
       string = '#!/bin/sh \n echo "hello"'
       command = 'sh -'
       shell(string,command).send() --> ['hello']
       ( Similar to: echo '#!/bin/sh \n echo "hello"' | sh - )
    shell().script()
      self.script    -- a list of strings, each a line that will become a script.
      self.sublist   -- list of values to be substituted at runtime.
      self.valuelist -- list of values that will take sublist's place.
                     -- valuelist *must* match sublist
      -- prints a 'script' from memory.
    """
    if args:
      self.command = args[0]
      self.args = args
    if len(args) > 1:
      self.remote = args[1]
    if options:
      self.options = options
    if not options:
      self.options = {}

    self.output = 'NULL'
  
  def run(self):
    command = self.command
    delnoerr = False ; shellval = False ; noerrval = True ; output= []
    for key in self.options.keys():
      if key == 'noerr': noerrval = self.options['noerr'] ; delnoerr = True
      if key == 'shell': shellval = self.options['shell']
    if delnoerr: del self.options['noerr']
    if not shellval: command = shlex.split(command)
    runpipe = Popen(command,stdout=PIPE,stderr=PIPE,**self.options)
    if noerrval:
      for result in runpipe.communicate()[0].split('\n'):
        for line in result.split('\n'):
          if not len(line) == 0:
            output.append(line)
    if not noerrval:
      for result in runpipe.communicate():
        for line in result.split('\n'):
          if not len(line) == 0:
            output.append(line)
    self.output = output
    return self.output

  def send(self):
    command = self.command ; remote = self.remote
    delnoerr = False ; noerrval = True ; output = []
    for key in self.options.keys():
      if key == 'noerr': noerrval = self.options['noerr'] ; delnoerr = True
    if delnoerr: del self.options['noerr']
    sendpipe=Popen(remote,shell=True,stdin=PIPE,stdout=PIPE,stderr=PIPE,**self.options)
    if not noerrval:
      for result in sendpipe.communicate(input=command):
        for line in result.split('\n'):
          if len(line):
            output.append(line)
    if noerrval:
      for result in sendpipe.communicate(input=command)[0].split('\n'):
        if len(result):
          output.append(result)
    self.output = output
    return self.output

  def script(self):
    self.script = []
    self.sublist = []
    self.valuelist = []
    mem = StringIO.StringIO()
    for line in self.script:
      for item in self.sublist:
        pos = self.sublist.index(item)
        value = valuelist[pos]
        line = line.replace(item,value)
        print >>mem, line
    self.output = mem.getvalue()
    return self.output

  def iters(self): return range(len(self.command))[-1]
  
  def dedup(self): return list(set(self.command))
