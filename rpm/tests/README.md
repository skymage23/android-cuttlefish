## RPM Testing
This code tests the RPM package building scripts and SPEC files.

# Methodology:
We require Docker, as we use it in order to simulate fresh Fedora installs.
This also lets us test our RPM scripts and SPEC files against as many test
scenarios as feasible, wherein a "test scenario" is narrowly defined as a
reasonable, initial system state of any user wishing to install our RPMs.



# Requirements:

python3 >= 3.11.1

docker

docker-py

# Running tests:
Run "./tests_main.py" from the shell.