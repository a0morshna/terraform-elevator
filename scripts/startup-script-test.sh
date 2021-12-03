#!/bin/bash

# install jenkins

sudo apt update -y
sudo apt-get install openssh-server -y
sudo apt install openjdk-8-jdk -y

wget -qO - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'

sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

mkdir jenkins
cd jenkins

cat <<EOF > jenkins_user.sh
#!/bin/bash

function createJenkinsUser {

	sudo apt-get update -y
	
	echo "Creating jenkins user"

	sudo useradd -m -d /var/lib/jenkins -s /bin/bash -G sudo jenkins 

	echo "making jenkins as sudo user"

	sudo usermod -aG sudo jenkins

	nopasswdEntry=`cat /etc/sudoers | grep 'jenkins' | wc -l`

	if [ $nopasswdEntry -eq 0 ]
    then
	    echo "Making nopasswd entry in sudoers file"
	    echo 'jenkins  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers  
	fi
}
createJenkinsUser

EOF

sudo /bin/bash jenkins_user.sh


cd /var/lib/jenkins
mkdir init.groovy.d
cd init.groovy.d


cat <<EOF > 01-admin-user.groovy

/*
 * Create an admin user.
 */
import jenkins.model.*
import hudson.security.*

println "--> creating admin user"

//def adminUsername = System.getenv(${login})
//def adminPassword = System.getenv(${password})

def adminUsername = "${login}"
def adminPassword = "${password}"

assert adminPassword != null : "No ADMIN_USERNAME env var provided, but required"
assert adminPassword != null : "No ADMIN_PASSWORD env var provided, but required"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUsername, adminPassword)
Jenkins.instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
Jenkins.instance.setAuthorizationStrategy(strategy)

Jenkins.instance.save()

EOF

sudo systemctl restart jenkins


cat <<EOF > 02-plugins.groovy

import jenkins.*
import hudson.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;
import hudson.model.*
import jenkins.model.*
import hudson.security.*

final List<String> REQUIRED_PLUGINS = [
        "workflow-aggregator",
        "ws-cleanup",
        "ant",
        "antisamy-markup-formatter",
        "authorize-project",
        "build-timeout",
        "cloudbees-folder",
        "configuration-as-code",
        "credentials-binding",
        "email-ext",
        "git",
        "github-branch-source",
        "gradle",
        "ldap",
        "mailer",
        "matrix-auth",
        "pam-auth",
        "pipeline-github-lib",
        "pipeline-stage-view",
        "ssh-slaves",
        "timestamper",
        "workflow-aggregator",
        "ws-cleanup",
]

if (Jenkins.instance.pluginManager.plugins.collect {
  it.shortName
}.intersect(REQUIRED_PLUGINS).size() != REQUIRED_PLUGINS.size()) {
  REQUIRED_PLUGINS.collect {
    Jenkins.instance.updateCenter.getPlugin(it).deploy()
  }.each {
    it.get()
  }
  Jenkins.instance.restart()
  println 'Run this script again after restarting to create the jobs!'
  throw new RestartRequiredException(null)
}

println "Plugins were installed successfully"

EOF


sudo systemctl restart jenkins