#!/usr/bin/env python3
import sys
import struct
import os

from collections import deque
from statistics import mean

class DequeHandler():

    l1tol2 = None
    l1tol3 = None
    l1tol4 = None
    l1tol5 = None
    l1tol6 = None
    l1tol7 = None
    l1tol8 = None
    l2tol1 = None
    l2tol3 = None
    l2tol4 = None
    l2tol5 = None
    l2tol6 = None
    l2tol7 = None
    l2tol8 = None
    l3tol1 = None
    l3tol2 = None
    l3tol4 = None
    l3tol5 = None
    l3tol6 = None
    l3tol7 = None
    l3tol8 = None
    l4tol1 = None
    l4tol2 = None
    l4tol3 = None
    l4tol5 = None
    l4tol6 = None
    l4tol7 = None
    l4tol8 = None
    l5tol1 = None
    l5tol2 = None
    l5tol3 = None
    l5tol4 = None
    l5tol6 = None
    l5tol7 = None
    l5tol8 = None
    l6tol1 = None
    l6tol2 = None
    l6tol3 = None
    l6tol4 = None
    l6tol5 = None
    l6tol7 = None
    l6tol8 = None
    l7tol1 = None
    l7tol2 = None
    l7tol3 = None
    l7tol4 = None
    l7tol5 = None
    l7tol6 = None
    l7tol8 = None
    l8tol1 = None
    l8tol2 = None
    l8tol3 = None
    l8tol4 = None
    l8tol5 = None
    l8tol6 = None
    l8tol7 = None

    stats = {}

    def getDeque(self, attrname):
        return getattr(self,attrname)

    def initDeque(self, attrname):
        setattr(self,attrname,deque(maxlen=100))

    def getDequeAverage(self, attrname):
        tmp = getattr(self,attrname)
        return mean(tmp)


class ReroutingStatsHandler():

    stats = {}

    def getStats(self):
        return self.stats
