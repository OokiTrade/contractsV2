#!/usr/bin/python3

class fixedint(object):
    def __init__(self, num):   
        self.num = int(num)
    def __eq__(self, num):
        return str(self.num) == str(num)
    def __repr__(self):
        return str(self.num)
    def __str__(self):
        return str(self.num)
    def __int__(self):
        return int(self.num)
    def __float__(self):
        return int(self.num)

    def add(self, num):
        self.num = int(int(self.num) + int(num))
        return self
    def sub(self, num):
        self.num = int(int(self.num) - int(num))
        return self
    def mul(self, num):
        self.num = int(int(self.num) * int(num))
        return self
    def div(self, num):
        self.num = int(int(self.num) // int(num))
        return self