#!/usr/bin/env python

import csv
import json
import os
import sys
import time

DATE = 'DATE'
TIME = 'TIME'
TIME_GRANULARITY = 300000 # 5-minutes

LATEST_TIME = int(sys.argv[1])  # eg 0 or 1449269400000
METRIC = sys.argv[2]  # eg 'R1_TOP_AVG_CAL'

def ProcessFile(filename, obj={}):
  f = open(filename, 'r')
  columns = f.readline().replace('\r\n','').split(', ')
  columns = [c.upper() for c in columns]
  if METRIC not in columns:
    print >>sys.stderr, "  %s not in this file!" % METRIC
    return
  reader = csv.DictReader(f, columns)

  for row in reader:
    try:
      t = time.strptime(row[DATE] + ' ' + row[TIME] + ' MST', '%m/%d/%Y %H:%M:%S.%f %Z')
    except:
      print >>sys.stderr, "  bad date."
      continue
    tstr = int(time.mktime(t) * 1000 / TIME_GRANULARITY) * TIME_GRANULARITY

    if LATEST_TIME is not None and tstr < LATEST_TIME:
      continue

    if row[METRIC] is None:
      print >>sys.stderr, "  busted row."
      continue
    val = float(row[METRIC])
    obj[tstr] = val

def Dump(obj):
  data = []
  for k in sorted(obj.keys()):
    data.append([k, obj[k]])
  print json.dumps(data)

def Dump2(obj):
  data = []
  for k in sorted(obj.keys()):
    print "renature-dashboard.appspot.com/publish?time=%s&val=%s&metric=%s" % (k, obj[k], METRIC)
    #data.append([k, obj[k]])
  #print json.dumps(data)

obj = {}
for fname in sys.argv[3:]:
  print >>sys.stderr, 'Reading ' + fname
  ProcessFile(fname, obj)
if LATEST_TIME == 1446350400000:
  Dump(obj)
else:
  Dump2(obj)

