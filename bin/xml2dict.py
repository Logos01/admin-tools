#!/usr/bin/python

"""
Converts XML data into nested dictionary structure.
Handles elements and text items only.

Created 2012-11-06 by Logos01

Usage:

xml2dict.xml2dict('xmlfile1.xml'<,'xmlfile2.xml','xmlfile..n.xml'>).output
  -- ".output" used to return results due to __init__ requirement of returning only None.
"""
import xml 
from xml.dom import minidom as mdom
import re

class xml2dict:
  def __init__(self,*args,**options):
    global xmlroot
    if len(args) == 1:
      xmlroot = mdom.parse(args[0]).firstChild
      self.output = self.converttodict(xmlroot)
    if len(args) > 1:
      self.output = {}
      for x in args:
        xmlroot = mdom.parse(x).firstChild
        self.output[x] = self.converttodict(xmlroot)

  def genelementlist(self,input):
    return [ str(x.localName) for x in input.childNodes if str(x.localName) != 'None' ]
  
  def nestedattribute(self,input):
    if input.__class__ == xml.dom.minidom.Element:
      input = input.childNodes
    if input.__len__() == 1:
      input = input[0]
      if input.nodeType == 3:
        output = str(input.data)
      if input.nodeType == 1:
        output = self.nestedattribute(input) 
    else:
      outputdict = {}
      for x in input:
        localname = str(x.localName)
        if x.__class__ == mdom.Element:
          outputdict[localname] = self.nestedattribute(x)
        if x.__class__ == mdom.Text:
          if not re.search('\n',str(x.data)):
            outputdict[localname] = str(x.data)
      output = outputdict
    return output
  
  
  def converttodict(self,input):
    elementslist = self.genelementlist(xmlroot)
    elementsdict = {}
    for x in elementslist:
      elementsdict[x] = xmlroot.getElementsByTagName(x)
      elementsdict[x] = elementsdict[x][0]
      elementsdict[x] = elementsdict[x].childNodes
      elementsdict[x] = self.nestedattribute(elementsdict[x])
    return elementsdict
