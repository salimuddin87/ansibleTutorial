# Ansible Tutorial

# Roles
1. files --> contain reguler files those need to be copied to the target hosts.
2. handlers --> event handlers
3. meta --> role dependencies
4. templates --> similar to files, but contain dynamic data.
5. tasks --> playbook tasks
6. vars/group_vars --> variable defination

# Ansible commands
1. ansible-doc -l | more // list all modules
2. ansible-doc -s yum // list yum module options
3. ansible appgroup -m ping // calling ping module for appgroup mentioned in hosts file
4. ansible appgroup -m ping -o // output in single line
5. ansible all -m shell -a "uname -a; df -h" -v // To run shell command on all group defined in hosts
6. ansible appgroup -m yum -a "name=httpd state=present" -s
   (you must be root user to install pkg in a server)
7. ansible appgroup -m service -a "name=httpd state=started" -s
   (run the above command twice and see the difference in yellow and green)
8. ansible all -m yum -a "name=nmap state=present" -s
9. ansible all -m copy -a "src=/tmp/filename dest=/tmp/filename1" -s
10. ansible-playbook main.yml -i host1 --tags dns // to run dns tags on main.yml
