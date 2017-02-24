#Get the path of the minion. 
#Need to find a way to set it permanently. it is not working like it should using: 
#cmd.run --> export PATH=$PATH:/opt/puppetlabs/bin
#maybe just symlink it and call it a day :)
{% set current_path = salt['environ.get']('PATH', '/bin:/usr/bin') %}

#this isn't the best way to add repos but i am lazy. 
#it will fail but the repo is still added
add repos:
  pkg.installed:
    - pkgs:
      - https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
      - https://yum.theforeman.org/releases/1.14/el7/x86_64/foreman-release.rpm
    - order: 1

foreman-installer:
  pkg.installed:
#    - pkgs:
#      - foreman-installer
#      - tfm-rubygem-foreman_cockpit
    - order: 2

build foreman:
  cmd.run:
    - name: foreman-installer
    - require:
      - pkg: foreman-installer
    - require_in:
      - install puppet ntp module
      - apply master config
      - populate databases

#apply master config:
#  module.run:
#    - name: puppet.run

apply master config:
  cmd.run:
     - name: puppet agent --test
     - env:
       - PATH: {{ [current_path, '/opt/puppetlabs/bin']|join(':') }}


foreman firewalld:
  firewalld.present:
    - name: public
    - ports:
#      - 80/tcp        #Foreman UI (Apache)
      - 443/tcp        #Foreman UI (Apache)
      - 8443/tcp       #Smart Proxy
      - 8140/tcp       #Puppet Master
#      - 69/udp        #TFTP Server
      - 4505/tcp       #Salt Master
      - 4506/tcp       #Salt Master
    - services:
      - ssh

#this might not be necessary
populate databases:
  cmd.run:
    - name: foreman-rake db:migrate | foreman-rake db:seed | foreman-rake apipie:cache:index

#install puppet ntp module:
#  module.run:
#    - name: puppet.run
#    - args: module install puppetlabs/ntp

install puppet ntp module:
  cmd.run:
    - name: puppet module install puppetlabs/ntp
    - env:
      - PATH: {{ [current_path, '/opt/puppetlabs/bin']|join(':') }}
