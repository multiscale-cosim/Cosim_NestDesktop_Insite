#!/bin/bash

#
# USAGE:
#   a) using defaults <BASELINEPATH>=${HOME} <GITUSERNAME>=multiscale-cosim
#           sh ./TVB_NEST-usecase1_ubuntu_setting_up.sh
#
#   b) specifiying the parameters
#        sh ./TVB_NEST_usecase1_ubuntu_setting_up.sh <BASELINEPATH> <GITUSERNAME>
#       e.g.
#           ./TVB_NEST_usace1_ubuntu_setting_up.sh /opt/MY_COSIM sontheimer

BASELINE_PATH="/home/vagrant"
BASELINE_PATH=${1:-${BASELINE_PATH}}

GIT_DEFAULT_NAME='multiscale-cosim'
GIT_DEFAULT_NAME=${2:-${GIT_DEFAULT_NAME}}

#
# STEP 1 - Setup folder locations
#

[ -d ${BASELINE_PATH} ] \
	|| (echo "${BASELINE_PATH} does not exists"; exit 1;)

#
# Full base path where installation happends:
#
# CO_SIM_ROOT_PATH = /home/<user>/multiscale-cosim/
# or
# CO_SIM_ROOT_PATH = /home/<user>/<git_account_name>/
#
CO_SIM_ROOT_PATH=${BASELINE_PATH}/${GIT_DEFAULT_NAME}

mkdir -p ${CO_SIM_ROOT_PATH}; cd ${CO_SIM_ROOT_PATH}

# CO_SIM_REPOS=${CO_SIM_ROOT_PATH}/cosim-repos
CO_SIM_SITE_PACKAGES=${CO_SIM_ROOT_PATH}/site-packages
CO_SIM_NEST_BUILD=${CO_SIM_ROOT_PATH}/nest-build
CO_SIM_NEST=${CO_SIM_ROOT_PATH}/nest-installed
CO_SIM_INSITE=${CO_SIM_ROOT_PATH}/insite

#
# STEP 2 - Install linux packages
#
# STEP 2.1 - Install base packages
#

# Update and upgrade installed base packages
sudo apt update && sudo apt upgrade -y

# Add repository for cmake 3.18+ (currently 3.27)
sudo apt update && sudo apt install -y software-properties-common lsb-release
sudo wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"

# Install packages
sudo apt install -y build-essential cmake git python3 python3-pip

#
# STEP 2.2 - packages used by NEST, TVB and the use-case per se
#
# NEST: https://nest-simulator.readthedocs.io/en/v3.5/installation/noenv_install.html
sudo apt install -y \
        cython3 \
        doxygen \
        libboost-all-dev \
        libgsl-dev \
        libltdl-dev \
        libncurses-dev \
        libreadline-dev \
        mpich

sudo apt clean all

#
# STEP 2.3 - switching the default MPI installed packages to MPICH
#   Selection    Path                     Priority   Status
#------------------------------------------------------------
#* 0            /usr/bin/mpirun.openmpi   50        auto mode
#  1            /usr/bin/mpirun.mpich     40        manual mode
#  2            /usr/bin/mpirun.openmpi   50        manual mode
echo "1" | sudo update-alternatives --config mpi 1>/dev/null 2>&1 # --> choosing mpich
echo "1" | sudo update-alternatives --config mpirun 1>/dev/null 2>&1 # --> choosing mpirun

#
# STEP 3 - Install Python packages of TVB, NEST Desktop (and dependencies for NEST Server)
#
# NOTE: Specific versions are required for some packages
pip install --no-cache --upgrade --target=${CO_SIM_SITE_PACKAGES} \
        cython \
        elephant \
        flask \
        flask-cors \
        gunicorn \
        mpi4py \
        nest-desktop==3.3.0a2 \
        numpy==1.23 \
        pyzmq \
        requests \
        restrictedpython \
        testresources \
        tvb-contrib==2.2 \
        tvb-data==2.0 \
        tvb-gdist==2.1 \
        tvb-library==2.2

#
# STEP 4 - Install NEST
#
# International Neuroinformatics Coordinating Facility (INCF)
# https://github.com/INCF/MUSIC
# https://github.com/INCF/libneurosim

git clone --single-branch https://github.com/nest/nest-simulator.git
cd nest-simulator
# 9cb3cb: Merge pull request from VRGroupRWTH/feature/device_label (https://github.com/nest/nest-simulator/commit/9cb3cb2ec1cc76e278ed7e9a8850609fdb443cae)
# TODO: Needed until NEST v3.6 release to incorporate the aforementioned pull request.
git checkout 9cb3cb

# Cython
PATH=${CO_SIM_SITE_PACKAGES}/bin:${PATH}
PYTHONPATH=${CO_SIM_SITE_PACKAGES}:${PYTHONPATH:+:$PYTHONPATH}

mkdir -p ${CO_SIM_NEST_BUILD}; cd ${CO_SIM_NEST_BUILD}

# https://nest-simulator.readthedocs.io/en/v3.5/installation/cmake_options.html#cmake-options
cmake -DCMAKE_INSTALL_PREFIX:PATH=${CO_SIM_NEST} \
    ${CO_SIM_ROOT_PATH}/nest-simulator \
    -Dwith-mpi=ON

make -j 4 install
cd ${CO_SIM_ROOT_PATH}

#
# STEP 5 - Install Insite
#
sudo apt install -y libssl-dev
mkdir -p $CO_SIM_INSITE; cd $CO_SIM_INSITE
git clone --recurse-submodules https://github.com/VRGroupRWTH/insite.git ${CO_SIM_INSITE}/insite

cd ${CO_SIM_INSITE}/insite
# git checkout v2.1.1

mkdir build_access_node; cd build_access_node
cmake ../access-node -DBUILD_SHARED_LIBS=OFF
sudo make -j 4 install

cd ${CO_SIM_INSITE}/insite
mkdir build_nest_module; cd build_nest_module
cmake -Dwith-nest=${CO_SIM_NEST}/bin/nest-config ../nest-module -DSPDLOG_INSTALL=ON
sudo make -j 4 install

#
# STEP 6 - WORK-AROUNDs (just in case)
#
# removing typing.py as work-around for pylab on run-time
rm -f ${CO_SIM_SITE_PACKAGES}/typing.py
#
# proper versions to be used by TVB
# removing (force) the installed versions
# __? rm -Rf ${CO_SIM_SITE_PACKAGES}/numpy
# __? rm -Rf ${CO_SIM_SITE_PACKAGES}/gdist
# __? pip install --target=${CO_SIM_SITE_PACKAGES} --upgrade --no-deps --force-reinstall --no-cache matplotlib numpy==1.21
# __? pip install --target=${CO_SIM_SITE_PACKAGES} --upgrade --no-deps --force-reinstall gdist==1.0.2

# even though numpy==1.21 coud have been installed,
# other version could be still present and used

# if false; then
# continue_removing=1
# while [ ${continue_removing} -eq 1 ]
# do
#         pip list | grep numpy | grep -v "1.21" 1>/dev/null 2>&1
#         if [ $? -eq 0 ]
#         then
#                 pip uninstall -y numpy 1>/dev/null 2>&1
#         else
#                 continue_removing=0
#         fi
# done
# fi

#
# STEP 7 - Clone cosim github repos
#
cd ${CO_SIM_ROOT_PATH}
git clone --recurse-submodules --jobs 4 https://github.com/${GIT_DEFAULT_NAME}/Cosim_NestDesktop_Insite.git

#
# STEP 8 - Generate the .source file based on ENV variables
#
NEST_PYTHON_PREFIX=`find ${CO_SIM_NEST} -name site-packages`
CO_SIM_USE_CASE_ROOT_PATH=${CO_SIM_ROOT_PATH}/Cosim_NestDesktop_Insite
CO_SIM_MODULES_ROOT_PATH=${CO_SIM_ROOT_PATH}/Cosim_NestDesktop_Insite

SUFFIX_PYTHONPATH="\${PYTHONPATH:+:\$PYTHONPATH}"

cat <<.EOSF > ${CO_SIM_ROOT_PATH}/Cosim_NestDesktop_Insite.source
#!/bin/bash
export CO_SIM_ROOT_PATH=${CO_SIM_ROOT_PATH}
export CO_SIM_USE_CASE_ROOT_PATH=${CO_SIM_USE_CASE_ROOT_PATH}
export CO_SIM_MODULES_ROOT_PATH=${CO_SIM_MODULES_ROOT_PATH}

export PYTHONPATH=${CO_SIM_MODULES_ROOT_PATH}:${CO_SIM_SITE_PACKAGES}:${NEST_PYTHON_PREFIX}${SUFFIX_PYTHONPATH}
export PATH=${CO_SIM_SITE_PACKAGES}/bin:${PATH}

# Source env variables for NEST
source ${CO_SIM_NEST}/bin/nest_vars.sh
.EOSF

#
# STEP 9 - Generate the run_on_local.sh
#
cat <<.EORF > ${CO_SIM_ROOT_PATH}/run_on_local.sh

# checking for already set CO_SIM_* env variables
CO_SIM_ROOT_PATH=\${CO_SIM_ROOT_PATH:-${CO_SIM_ROOT_PATH}}
CO_SIM_USE_CASE_ROOT_PATH=\${CO_SIM_USE_CASE_ROOT_PATH:-${CO_SIM_USE_CASE_ROOT_PATH}}
CO_SIM_MODULES_ROOT_PATH=\${CO_SIM_MODULES_ROOT_PATH:-${CO_SIM_MODULES_ROOT_PATH}}

# exporting CO_SIM_* env variables either case
export CO_SIM_ROOT_PATH=\${CO_SIM_ROOT_PATH}
export CO_SIM_USE_CASE_ROOT_PATH=\${CO_SIM_USE_CASE_ROOT_PATH}
export CO_SIM_MODULES_ROOT_PATH=\${CO_SIM_MODULES_ROOT_PATH}

# CO_SIM_ site-packages for PYTHONPATH
export CO_SIM_PYTHONPATH=${CO_SIM_MODULES_ROOT_PATH}:${CO_SIM_SITE_PACKAGES}:${NEST_PYTHON_PREFIX}

# adding EBRAIN_*, site-packages to PYTHONPATH (if needed)
PYTHONPATH=\${PYTHONPATH:-\$CO_SIM_PYTHONPATH}
echo \$PYTHONPATH | grep ${CO_SIM_SITE_PACKAGES} 1>/dev/null 2>&1
[ \$? -eq 0 ] || PYTHONPATH=\${CO_SIM_PYTHONPATH}:\$PYTHONPATH
export PYTHONPATH=\${PYTHONPATH}

# making nest binary reachable
# __ric__? PATH=\${PATH:-$CO_SIM_NEST/bin}
echo \$PATH | grep ${CO_SIM_NEST}/bin 1>/dev/null 2>&1
[ \$? -eq 0 ] || export PATH=$CO_SIM_NEST/bin:\${PATH}

# start NEST Desktop
export NEST_DESKTOP_HOST=0.0.0.0
nest-desktop start &

# start Insite Access node
insite-access-node &

# start CoSim
python3 \${CO_SIM_USE_CASE_ROOT_PATH}/main.py \\
    --global-settings \${CO_SIM_MODULES_ROOT_PATH}/EBRAINS_WorkflowConfigurations/general/global_settings.xml \\
    --action-plan \${CO_SIM_USE_CASE_ROOT_PATH}/userland/configs/local/plans/cosim_alpha_brunel_local.xml

.EORF

cat <<.EOKF >${CO_SIM_ROOT_PATH}/kill_co_sim_PIDs.sh
for co_sim_PID in \`ps aux | grep Cosim_NestDesktop_Insite | sed 's/user//g' | sed 's/^ *//g' | cut -d" " -f 1\`; do kill -9 \$co_sim_PID; done
.EOKF

echo "SETUP DONE!"
