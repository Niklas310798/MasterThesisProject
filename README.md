# Niklas Schwingeler MA2021
## Repository structure
|-paper: papers used in citations \
|-presentation: presentations \
|-README.md: this file \
|-src: contains source code \
|-text: thesis written in latex \
|-thesis.pdf: final thesis


## Prepare VM for Recreating Prototyping Environment

Base VM is the prepared P4 Tutorial Dev VM by Andy Fingerhut, found here:
https://github.com/jafingerhut/p4-guide/blob/master/bin/README-install-troubleshooting.md

**Note:** Used September 2022 Version

**Note:** Steps 1 to 5 below are done for all cloned versions of current working VM (P4 Dev Final)


### 1. Preparing VirtualBox Env for proper usage of VM on Windows

If issues with the VirtualBox Environment occur (window not autoscaling/autosizing correctly):
Might be necessary to install VirtualBox Guest Additions (at least latest version)

Helpful link: https://askubuntu.com/questions/1245675/copy-and-paste-not-working-in-ubuntu-in-virtualbox-6-1-2

```
sudo apt update
sudo apt upgrade
sudo apt install build-essential dkms linux-headers-$(uname -r)
sudo apt install virtualbox-guest-additions-iso
sudo apt install virtualbox-guest-x11
sudo VBoxClient --clipboard
```

Set Keyboard Layout and Timezone to appropriate settings for Germany
	- Preferences > LXqT Settings > Keyboard and Mouse/Time and Date
Activate Copy and Paste between Host and Guest
  - Device > Shared Clipboard > bidirectional


### 2. Setup SSH Keys to fetch required Git Repositories

Generate SSH Keys and import to Gitlab/Github

Helpful link: https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04

Login with user p4 (password: p4) and open terminal. Run `ssh-keygen` to generate RSA-2048 key pair.
Press enter to select default location for key pair files, type in and retype password if desired.
Type `cat ~/.ssh/id_rsa.pub` to print public key file, select and copy key hash.
Import that into Gitlab/Github account under Preferences > SSH/GPG Keys.

**Info:** Forked and modified behavioral-model repo into public repo into my personal Github account.
Cloned this repo twice into the prototype repo on GitLab, but adding the public key to personal Github account should not be necessary to fetch code to VM.


### 3. Install additional libraries/packages/modules

Install iperf3:
```
sudo apt install iperf3
```

Install Python Modules:
```
sudo pip install bitstring
sudo pip install matplotlib (not done in prepared VM Clones)
# sudo enables installing bitstring globally
```

**Note:** Scapy Version 2.4.5. shows issues while running the controller script, as it claims to not accept multiple interfaces to sniff on simultaneously. Step 7 shows an improvised solution, as it represents not proper python module installation into the dist-packages directory, but only copies the files of version 2.5.0 (current dev version) into prepared folders in `/usr/local/lib/python3.8/dist-packages`.
However, controller hosts are able to listen to all interfaces connected to leaf switches. Still, scapy is not working entirely correct, e.g. is not executable directly from CLI for interactive session.


### 4. Clone Project Git Repo to proper VM directory

Login with user p4 (password: p4). Navigate to tutorials directory and clone repo using SSH.
```
cd tutorials
git clone git@git.uni-due.de:ncs-thesis/Niklas-Schwingeler-MA2021.git
```

Doing so should also clone entire code of modified versions of behavioral-model as those are added as git submodules to project repo. If not, run `git submodule update` to fetch code to local machine.


### 5. Add modified behavioral-model as submodules to main project repo

**Note:** Should not be necessary, as this was being done within a previous commit and is part of the remote repo. However, for demonstration purposes, this is how it was done.

Helpful link: https://chrisjean.com/git-submodules-adding-using-removing-and-updating/

```
cd ~/tutorials/Niklas-Schwingeler-MA2021
git submodule add git@github.com:Niklas310798/behavioral-model.git src/helper/bmv2      # regular version (with logs)
git submodule add git@github.com:Niklas310798/behavioral-model.git src/helper/bmv2-opt  # optimized version for experiment
```


**=> All the steps above are done for all the cloned backup VM instances**

### 6. Install p4-utils to enable mx commands to execute commands in Mininet namespace

Helpful link: https://github.com/nsg-ethz/p4-utils#manual-installation

It was enough to run the install shell script in the root dir of the p4-utils github repository:
```
git clone https://github.com/nsg-ethz/p4-utils.git
cd p4-utils
sudo ./install.sh
```

**Note:** Requires Scapy 2.4.4, so it could be necessary to run `sudo pip install scapy=2.4.4` beforehand.


### 7. Build both version of BMv2 for optimized/testing experiment and one for debugging

#### Optional (not required for this project):
Install PI
```
cd /home/vagrant/PI
sudo ./autogen.sh
sudo .configure --with-proto --without-internal-rpc
sudo make
sudo make install
```

#### BMv2 variants

Regular variant: https://github.com/Niklas310798/behavioral-model/tree/main/targets/simple_switch_grpc
```
cd src/helper/bmv2
sudo ./autogen.sh
sudo ./configure --with-thrift --without-nanomsg
sudo make
```

Optimized variant: https://github.com/nsg-ethz/p4-learning/blob/master/exercises/07-Count-Min-Sketch/README.md
```
cd src/helper/bmv2-opt
sudo ./autogen.sh
sudo ./configure --without-nanomsg --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'
sudo make
```

Tested: sudo ./configure --with-pi --with-thrift --without-nanomsg --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'

- Requires --log-console from the simple_switch_grpc process to be deactivated in order to have no log messages be written to logfiles. Performance up to 15Mbit/s.

Depending on which version of bmv2 is required, go into corresponding root dir and run
```
sudo make install
sudo ldconfig
```

**Info:** Somehow does not work correctly yet. Using the optimized version requires the `src/helper/p4runtime_switch.py` script to be adapted and also `src/topo.py` to disable/remove all the logging parameters in order to stop the simple_switch_grpc processes to write logging information into corresponding log files. Still, seems to bring some performance enhancements according to slightly increasing bandwidth in iperf3 processes.


### 8. Fix scapy not reading list of interfaces to sniff on simultaneously

**UPDATE: Installing Scapy 2.4.4 works for this use case. Scapy able to sniff on multiple ports simultaneously. This fix below not necessary anymore!!!**


Updating scapy to 2.5.0 does not work using pip or apt (as 2.4.5 is latest release)

Copying the latest source code of 2.5.0 into /usr/local/lib/python3.8/dist-packages seemed to save the deal
However, running scapy from CLI then does not work anymore (METADATA file is missing in 2.5.0)

Script to do so must be run from user vagrant (first copy script to ~/ for user vagrant):
Run `./fix_scapy_to_v2.5.0_bug.sh`

Manual steps comprehended in the script:
```
cd /home/vagrant/
sudo git clone https://github.com/secdev/scapy.git
cd scapy
sudo python3 setup.py install
cd ..

sudo mkdir /usr/local/lib/python3.8/dist-packages/scapy-2.5.0rc01.dev18.dist-info

cd /home/vagrant/scapy/scapy.egg-info
sudo cp -a . /usr/local/lib/python3.8/dist-packages/scapy-2.5.0rc01.dev18.dist-info

cd /usr/local/lib/python3.8/dist-packages/
sudo rm -r scapy
sudo mkdir scapy
cd /home/vagrant/scapy/scapy
sudo cp -a . /usr/local/lib/python3.8/dist-packages/scapy
```


## Starting the Environment

After building and installing the desired version of bmv2 in the helper directory, you may startup the Mininet environment to drive some tests.

### Automated Experiment Startup

The system is designed to automatically run all tests based on a single configuration file in `conf/experiment_conf.json`. This file contains all scenarios, flow configurations and Mininet settings (e.g. bandwidth limitation). Also, iPerf and probe traffic configurations are set here.

Running the following code executes the experiment:
```
cd src
python experiment.py
```

You can start Mininet manually beforehand running `bash start_comp.sh`, otherwise running the experiment also starts the Mininet Environment and installs initial rule configuration on switches. If Mininet is already running, `experiment.py` skips starting Mininet and immediately starts running the experiment.

`Experiment.py` first deletes all previous iperf reports, controller logs and result plots. It also terminates all running iperf, probe, controller etc. commands if some are still running.

The experiment is conducted per scenario (different flow configuration, targeted iperf bandwidth, etc.) and runs a pre-configured number of runs, also set in the configuration file.
Compared are three programs:
* rerouting: Regular iperf traffic **plus** probe packets are sent, controllers run to calc latency **plus** watchdog runs to install rules if pending_rule files are written to corresponding directory
* probed: Regular iperf traffic **plus** probe packets are sent, controllers run to calc latency
* static: Regular iperf traffic only

Iperf traffic settings apply to all different programs in the same scenario.
After each run all the subprocesses (iperf server, controllers, probes, etc.) are terminated and freshly started for the next run.

When all the runs for every program in one scenario are finished the experiment automatically plots the results in form of a CDF to FCT graph.

When the entire experiment (all scenarios) is finished, results are copied to a shared folder directory named `/media/sf_Shared_with_VM`.

### Manual Startup

First startup script compiles the P4 scripts (may be disabled, as there are no more planned modifications in the P4 scripts) and fires up the topo script which builds the Mininet instance and the following topology. To compile and build topology **run** `bash start_comp.sh`.

TBD: Insert image of topology

All data center switches run the `vxlan_int.p4` script, all "internet" switches run the `ipv4_lpm.p4` script. First script applies INT information collection, second only applies IPv4 based forwarding using the outer headers of the VXLAN encapsulated packets (in case two hosts from different data centers are communicating).

Before running any traffic, the initial rule configurations must be applied to all switches. Exemplary default behavior of the switches, displayed by the initial rules, is described in the following image.
**Run** `bash config_switches.sh` to configure initial rules and mirroring sessions on switches.




### Overview on switch tables and desired behavior of tables
