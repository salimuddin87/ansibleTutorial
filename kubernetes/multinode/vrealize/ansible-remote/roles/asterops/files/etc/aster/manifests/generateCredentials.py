#
# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# Purpose: This script generates credentials needed for ICCS feature. The
#          following tasks are done by the script:
#
#    1) creates "credentials" directory to accomodate keys and certificates.
#    2) code has been added to create the ARC server and client certificates.
#    3) creation of mutual authentication keys for ICE.
#    4) the generation of the above keys and certificates are done based on the
#       security level (authentication / none) set.
#    5) certificates/keys are generated only if the security level is set
#       to "authentication".
#    6) certificates/keys are not generated if the security level is set
#        to "none".
#    7) error handling is added.
#

import os
import sys
import exceptions
import subprocess
import socket

securityConfigDirPath = "./"
credentialDir = securityConfigDirPath + "credentials"
passwordForServer = "password_for_server"
passwordForClient = "password_for_client"

# commands for ICE mutual authentication
iceMutualAuthCmds = \
[
  "openssl rand -base64 32 > " + credentialDir + "/mutual-auth-key-base64.txt",
  "chmod 400 " + credentialDir + "/mutual-auth-key-base64.txt"
]

# ARC mutual authentication - server key/certificates generation commands
serverCmdList = \
[
  "echo " + passwordForServer + " > " + credentialDir \
     + "/serverCertPassPhrase.txt",
  "openssl genrsa -des3 -passout file:" \
     + credentialDir + "/serverCertPassPhrase.txt -out " \
     + credentialDir + "/server.key 1024",
  "openssl rsa -passin file:" \
     + credentialDir + "/serverCertPassPhrase.txt -in " + credentialDir \
     + "/server.key -out " + credentialDir + "/server.key",
  "openssl req -new -key " + credentialDir + "/server.key -out " \
     + credentialDir + "/server.crt -x509 " \
     + "-subj '/C=US/ST=CA/L=SantaClara/O=bad_db/OU=Aster/CN=" \
     + socket.gethostname() + "'" + " -days 1825",
  "cp " + credentialDir + "/server.crt " + credentialDir + "/root.crt",
  "rm -f " + credentialDir + "/serverCertPassPhrase.txt"
]

# ARC mutual authentication - client key/certificates generation commands
clientCmdList = \
[
  "echo " + passwordForClient + " > " + credentialDir \
     + "/clientCertPassPhrase.txt",
  "openssl genrsa -des3 -passout file:" \
     + credentialDir + "/clientCertPassPhrase.txt -out " \
     + credentialDir + "/postgresql.key 1024",
  "openssl rsa -passin file:" \
     + credentialDir + "/clientCertPassPhrase.txt -in " + credentialDir \
     + "/postgresql.key -out " + credentialDir + "/postgresql.key",
  "openssl req -new -key " + credentialDir + "/postgresql.key -out " \
     + credentialDir + "/postgresql.csr " \
     + "-subj '/C=US/ST=CA/L=SantaClara/O=bad_db/OU=Aster/CN=beehive'",
  "openssl x509 -req -in " + credentialDir + "/postgresql.csr -CA "  \
  + credentialDir + "/root.crt -CAkey " + credentialDir + "/server.key -out " \
  + credentialDir + "/postgresql.crt -CAcreateserial -days 1825",

  # changing the permissions to 400
  "chmod 400 " + credentialDir + "/*",
  "rm -f " + credentialDir + "/clientCertPassPhrase.txt"
]

CONSTSTR_AUTHENTICATION = "authentication"
CONSTSTR_NONE = "none"

# exception class
class ClusterSecurityException(exceptions.Exception):
   pass

'''
This function does the following:
- Creates the ICE mutual authentication keys/certificates.
- Creates the ARC mutual authentication keys/certificates.
'''
def generateCredentials():
   try:
      # create credentials directory
      mkdirCmd = "mkdir -p " + credentialDir
      if os.path.isdir( credentialDir ) != True:
         retcode = subprocess.call(mkdirCmd, shell=True)
         if retcode != 0 :
            tempStr = "failed to create " + credentialDir + " directory."
            raise ClusterSecurityException(tempStr)
      if os.listdir(credentialDir):
         strCmd = "chmod 600 " + credentialDir + "/*"
         subprocess.call(strCmd, shell=True)
   except OSError as ex:
      tempStr = "error with creation of " + credentialDir \
                + " directory. Error: " + ex.strerror
      raise ClusterSecurityException(tempStr)
   except:
      raise ClusterSecurityException(sys.exc_info()[1])

   # generate ICE mutual authentication key/certificates
   try:
      for cmd in iceMutualAuthCmds:
         retcode = subprocess.call(cmd, shell=True)
         if retcode != 0:
            tempStr = "failed execution of command : " + cmd
            raise ClusterSecurityException(tempStr)
   except OSError as ex:
      tempStr = "execution failed:" + ex.strerror
      raise ClusterSecurityException(tempStr)

   # generate ARC server keys/certificates
   try:
      for cmd in serverCmdList:
         retcode = subprocess.call(cmd, shell=True)
         if retcode != 0:
            tempStr = "failed execution of command : " + cmd
            raise ClusterSecurityException(tempStr)
   except OSError as ex:
      tempStr = "execution failed:" + ex.strerror
      raise ClusterSecurityException(tempStr)

   # generate ARC client key/certificates
   try:
      for cmd in clientCmdList:
         retcode = subprocess.call(cmd, shell=True)
         if retcode != 0:
            tempStr = "failed execution of command : " + cmd
            raise ClusterSecurityException(tempStr)
   except OSError as ex:
      tempStr = "execution failed:" + ex.strerror
      raise ClusterSecurityException(tempStr)

# Note this currently writes the security config json file to the credentialDir.
# Also assumes that credentialDir exists before this is invoked.
def generateSecurityConfig(level="none"):
   startStr = \
   """{
      "IntraClusterCommunication": {
            "GlobalProtectionLevel": """
   endStr = "\n      }\n}\n"
   completeStr = startStr + '"' + level + '"' + endStr

   configFileName = "aster-security-config.json"
   configFilePath = credentialDir + "/" + configFileName

   # Remove the config file if it alreay exists.
   try:
      os.remove(configFilePath)
   except OSError:
      pass

   try:
      with open(configFilePath, "w") as configFile:
         configFile.write(completeStr)
   except OSError as ex:
      tempStr = "unable to write to file: " + configFilePath
      raise ClusterSecurityException(tempStr)

   retcode = subprocess.call("chmod 600 " + configFilePath, shell=True)
   if retcode != 0:
      tempStr = "unable to set permission for file: " + configFilePath
      raise ClusterSecurityException(tempStr)

if __name__ == "__main__":
# Note that currently the credentials as well as the security config file
# are generated if the argument to this script is either of 'authentication'
# or 'none'.
# The credentials will actually be used only when authentication is enabled
# but we still generate them when not using authentication as that enables us
# to maintain a single version of pod and container configuration yaml files
# which always mount the credentials as secrets on the containers.
   try:
      # process command line argument
      if len(sys.argv) == 2:
         if sys.argv[1] == CONSTSTR_AUTHENTICATION or \
            sys.argv[1] == CONSTSTR_NONE:
            generateCredentials()
            generateSecurityConfig(sys.argv[1])
         else:
            raise ClusterSecurityException("invalid argument value")
      else:
         raise ClusterSecurityException("invalid number of arguments")
   except:
      raise ClusterSecurityException(sys.exc_info()[1])


