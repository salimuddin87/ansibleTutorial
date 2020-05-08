#
# Purpose: This script is to dynamically change the port type of queenexec service 
# (ports 30002 and 30003) on kube-master while running the tests.
# The queenexec service ports were originally NodePort but it is changed to ClusterIP 
# to make it secure.
#

'''
Usage instructions:

python editPortType.py clusterip -> to change queenexec-service port type to ClusterIP
python editPortType.py nodeport -> to change queenexec-service port type to NodePort
'''

import os
import sys
import subprocess

kubectlGetSvc = "kubectl get service queenexec-service -n " \
                "cloud-aster -o yaml > queenexec-svc.yaml~"
kubectlReplace = "kubectl replace -f queenexec-svc.yaml"


def subprocess_cmd(command):
   process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).stdout.read()


class ChangePort:

   def nodePort(self):
      os.chdir('/tmp')
        
      # Checking if queenexec-service is running or not
      proc = subprocess.Popen(['kubectl', 'get', 'service', 'queenexec-service', '-n', 'cloud-aster'],
             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      terminalOutput, errorOutput = proc.communicate()
      if "Error from server (NotFound)" in errorOutput:
          print "queenexec-service not defined... Exiting!"
          sys.exit()
      else:
         subprocess_cmd(kubectlGetSvc)
         source = open("queenexec-svc.yaml~", "r")
         dest = open("queenexec-svc.yaml", "w")
         for line in source:
            if "targetPort" in line:
               newLine = line.replace('targetPort', 'nodePort')
               dest.write(newLine)
            elif "type: ClusterIP" in line:
               newLine = line.replace('ClusterIP', 'NodePort')
               dest.write(newLine)
            else:
               dest.write(line)
      source.close()
      dest.close()
      subprocess_cmd(kubectlReplace)
      subprocess_cmd("rm queenexec-svc.yaml~")
      subprocess_cmd("rm queenexec-svc.yaml")
      return
    
   def clusterIp(self):
      os.chdir('/tmp')
        
      '''
      A new yaml has to be created here because there is a field named 'resourceVersion'
      and once a yaml with a specific 'resourceVersion' has been applied, it cannot be 
      applied again.
      '''
        
      # Checking if queenexec-service is running or not
      proc = subprocess.Popen(['kubectl', 'get', 'service', 'queenexec-service', '-n', 'cloud-aster'],
             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      terminalOutput, errorOutput = proc.communicate()
      if "Error from server (NotFound)" in errorOutput:
         print "queenexec-service not defined... Exiting!"
         sys.exit()
      else:
         subprocess_cmd(kubectlGetSvc)
         source = open("queenexec-svc.yaml~", "r")
         dest = open("queenexec-svc.yaml", "w")
         for line in source:
            if "targetPort" not in line:
               if ("nodePort" in line):
                  newLine = line.replace('nodePort', "targetPort")
                  dest.write(newLine)
               elif ("type: NodePort" in line):
                  newLine = line.replace('NodePort', "ClusterIP")
                  dest.write(newLine)
               else:
                  dest.write(line)
      source.close()
      dest.close()
      subprocess_cmd(kubectlReplace)
      subprocess_cmd("rm queenexec-svc.yaml")
      subprocess_cmd("rm queenexec-svc.yaml~")
      return	


if __name__ == '__main__':
   changeport = ChangePort()
   try:
      if len(sys.argv) == 2:
         if sys.argv[1] == "nodeport":
            changeport.nodePort()
         elif sys.argv[1] == "clusterip":
            changeport.clusterIp()
         else:
            raise ValueError ("Please provide \'nodeport\' or \'clusterip\' as the command line argument")
      else:
         raise IndexError ("Invalid number of arguments")
   except Exception as e:
      print e
      sys.exit(1)
