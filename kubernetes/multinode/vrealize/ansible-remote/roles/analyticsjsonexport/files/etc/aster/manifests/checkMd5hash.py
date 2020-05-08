#!/home/beehive/toolchain/x86_64-unknown-linux-gnu/python-2.7.3/bin/python
#
# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# This script is used to verify exported UDFs json tar.  

import sys
import hashlib
import exceptions
import os

RETURN_TRUE = 0
RETURN_FALSE = 1

class UserException(exceptions.Exception):

   def __init__(self, msg, errCode):
      self.msg = msg
      self.errCode = errCode

   def getMsg(self):
      return self.msg

   def getErrCode(self):
      return self.errCode

try:
   tarFile = sys.argv[1]  # UDFs Json Tar
   tarFileCreated = sys.argv[2] # File containing md5hash value of UDFs Json Tar stored during json export process

   with open(tarFile) as tar_check:
      data = tar_check.read()
   calHash =  hashlib.md5(data).hexdigest()

   with open(tarFileCreated) as file_to_check:
      md5Val = file_to_check.read()

   if not md5Val == calHash:
      msg = "md5hash of UDFs json tarfile doesn't match\n"
      msg = msg + "Actual md5hash value = " + str(calHash) + "\n"
      msg = msg + "Expected md5hash value = " + str(md5Val)
      raise UserException(msg, RETURN_FALSE)

except UserException as e:
   print str(e.getMsg())
   os._exit(e.getErrCode())
except:
   msg = "ERROR: %s" % str(sys.exc_info()[0:2])
   print(msg)
   print('Exiting...')


