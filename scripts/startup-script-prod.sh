#!/bin/bash

# install git

sudo apt-get update
sudo apt install git

mkdir -p ansible-cicd/cronjob
cd ansible-cicd/cronjob

# add cron job 

cat <<EOF > cron.sh
#!/bin/sh

cd /ansible-cicd
sudo git init
sudo git pull https://github.com/a0morshna/ansible-cicd.git

cd /ansible-cicd
ansible-playbook playbook.yml

EOF


# add file where will be stored logs
cat <<EOF > job.log
---------logs--------

EOF


# enabled cron loging
sudo chmod 777 /etc/rsyslog.d/50-default.conf 
sudo cat <<EOF > /etc/rsyslog.d/50-default.conf 
cron.*             /var/log/cron.log

EOF
sudo systemctl restart rsyslog


# add permissions for user
echo 'alex0872m ALL=(ALL:ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo


# add cron job to crontab
cd ..
sudo chmod +x /ansible-cicd/cronjob/cron.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /ansible-cicd/cronjob/cron.sh  >> /ansible-cicd/cronjob/job.log 2>&1") | crontab -


sudo systemctl restart cron


cd /ansible-cicd

cat <<EOF > playbook.yml
---
- name: Install needed packages
  become: yes
  hosts:  localhost


  tasks:


  - name: Install python
    raw: apt-get update && apt-get install -y python3


  - name: Install  pip
    apt:
      name:
        - python3-pip


  - name: Install some python3 global deps
    pip:
      name:
        - packaging
        - appdirs
      state: latest
      executable: pip3


  - name: Install python3 dependencies
    pip:
      name:
        - wheel
        - setuptools
      executable: pip3
      state: latest



- name: File checking
  become: yes
  hosts: localhost


  vars:
    jenkins_host:  http://${jenkins-test_public_ip}:8080/job/cicd/lastStableBuild/api/json?tree=artifacts%5BrelativePath%5D
    jenkins_user: ${login}
    jenkins_password: ${password}


  tasks:


    - name: Make dir for all txt/json files
      file:
        path: /ansible-cicd/files
        state: directory


    - name: Get url response
      uri:
        url: "{{ jenkins_host }}"
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_password }}"
        method: GET
        force_basic_auth: yes
      register: pl_list_artifacts


    - name: Write all data in json
      copy:
        content="{{ pl_list_artifacts }}"
        dest=/ansible-cicd/files/pl_list_artifacts.json


    - name: Get path and filename
      shell: |
        grep -oE "[0-9]+/+[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/pl_list_artifacts.json | awk '!a[$0]++' > /ansible-cicd/files/pl_path.txt


    - name: Get whl filename
      shell: |
        grep -oE "[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/pl_path.txt | awk '!a[$0]++' > /ansible-cicd/files/pl_filename.txt


    - name: Check if any .whl file exist
      shell: |
        if ls /ansible-cicd/*.whl 1>/dev/null 2>&1
        then
          echo "Exist"
        fi
      register: file_result
      

    - name: Debug
      debug:
        var: file_result


    - block:

        - name: File doesn't exist
          command: ansible-playbook playbook2.yml

      when: file_result.stdout != "Exist"


    - block:

        - name: File exist
          command: ansible-playbook playbook1.yml

      when: file_result.stdout == "Exist"

EOF

sudo chmod 777 playbook.yml


cat <<EOF > playbook1.yml
---
- name: Register files
  become: yes
  hosts: localhost


  vars:

    jenkins_host:  http://${jenkins-test_public_ip}:8080/job/cicd/lastStableBuild/api/json?tree=artifacts%5BrelativePath%5D
    jenkins_user: ${login}
    jenkins_password: ${password}
    whl_test_dest: /ansible-cicd/test/
    whl_dest: /ansible-cicd/


  tasks:


    - name: Make test dir
      file:
        path: /ansible-cicd/test
        state: directory


    - name: Get url response
      uri:
        url: "{{ jenkins_host }}"
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_password }}"
        dest: "{{ whl_test_dest }}"
        method: GET
        force_basic_auth: yes
      register: list_test_artifacts


    - name: Write response data in json
      copy:
        content="{{ list_test_artifacts }}"
        dest=/ansible-cicd/files/pl1_list_artifacts.json


    - name: Get path and filename
      shell: |
        grep -oE "[0-9]+/+[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/pl1_list_artifacts.json | awk '!a[$0]++' > /ansible-cicd/files/pl1_path_test.txt


    - name: Get whl filename
      shell: |
        grep -oE "[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/pl1_path_test.txt | awk '!a[$0]++' > /ansible-cicd/files/pl1_filename_test.txt



- name: Comapre exist file and test file
  hosts: localhost
  become: yes


  vars :

    jenkins_wheel:  http://${jenkins-test_public_ip}:8080/job/cicd/lastSuccessfulBuild/
    jenkins_user: ${login}
    jenkins_password: ${password}
    whl_test_dest: /ansible-cicd/test/
    whl_dest: /ansible-cicd/


  tasks:


    - name: Get response
      uri:
        url: "{{ jenkins_wheel }}/artifact/{{  lookup('file', 'pl1_path_test.txt') }}"
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_password }}"
        dest: "{{ whl_test_dest }}"
        method: GET
        force_basic_auth: yes
        return_content: yes


    - name: Install wheel package
      shell: |
        cd /ansible-cicd/test
        pip3 install "{{ lookup('file', 'pl1_filename_test.txt') }}"


    - name: Register test filename
      stat:
        path: "{{ whl_test_dest }}"
      register: test_file


    - name: Reqister existing filename
      stat:
        path: "{{ whl_dest }}"
      register: exist_file


    - name: Compare files if they equal or not
      shell: |
        if [ $exist_file -ne $test_file  ]
        then
          echo "False"
        else
          echo "True"
        fi
      register: result


    - name: Debug
      debug:
        var: result


    - block:

        - name: Delete previous version
          shell: |
            cd /ansible-cicd
            sudo rm *.whl


        - name: If files not equal
          shell: |
            cd /ansible-cicd/test
            mv "{{ lookup('file', 'pl1_filename_test.txt') }}" /ansible-cicd
            cd /ansible-cicd
            sudo rm -r test

      when: result.stdout == "False"


    - block:

        - name: If files equal
          shell: |
            cd /ansible-cicd
            sudo rm -r test

      when: result.stdout == "True"

EOF

sudo chmod 777 playbook1.yml


cat <<EOF > playbook2.yml
---

- name: Get filename
  become: yes
  hosts: localhost

  vars:
    jenkins_host:  http://${jenkins-test_public_ip}:8080/job/cicd/lastStableBuild/api/json?tree=artifacts%5BrelativePath%5D
    jenkins_user: ${login}
    jenkins_password: ${password}
    whl_dest: /ansible-cicd/files/

  tasks:

    - name: Make files dir
      file:
        path: /ansible-cicd/files
        state: directory


    - name: Get response data
      uri:
        url: "{{ jenkins_host }}"
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_password }}"
        method: GET
        force_basic_auth: yes
      register: list_artifact


    - name: Write response data in json
      copy:
        content="{{ list_artifact }}"
        dest=/ansible-cicd/files/list_artifacts.json


    - name: Get path and filename
      shell: |
        grep -oE "[0-9]+/+[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/list_artifacts.json | awk '!a[$0]++' > /ansible-cicd/files/path.txt


    - name: Get whl filename
      shell: |
        grep -oE "[a-zA-Z0-9_.-]+.whl" /ansible-cicd/files/path.txt | awk '!a[$0]++' > /ansible-cicd/files/filename.txt



- name: Instal new version
  become: yes
  hosts: localhost

  vars:
    jenkins_wheel: http://${jenkins-test_public_ip}:8080/job/cicd/lastSuccessfulBuild/
    jenkins_user: ${login}
    jenkins_password: ${password}
    whl_dest: /ansible-cicd/

  tasks:

    - name: Get data
      uri:
        url: "{{ jenkins_wheel }}/artifact/{{  lookup('file', 'path.txt') }}"
        user: "{{ jenkins_user }}"
        password: "{{ jenkins_password }}"
        dest: "{{ whl_dest }}"
        method: GET
        force_basic_auth: yes
        return_content: yes


    - name: Install wheel package
      command: pip3 install "{{ lookup('file', 'filename.txt') }}"


EOF

#install ansible

sudo chmod +x playbook2.yml

sudo apt-get update -y
sudo apt-get install --no-install-recommends -y software-properties-common -y 
sudo apt-add-repository ppa:ansible/ansible -y

sudo apt-get update -y
sudo apt-get install -y ansible

