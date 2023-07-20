# killall -9 python3
# killall -9 mpirun

export CO_SIM_ROOT_PATH="/home/vagrant/multiscale-cosim"
export CO_SIM_MODULES_ROOT_PATH="${CO_SIM_ROOT_PATH}/Cosim_NestDesktop_Insite"
export CO_SIM_USE_CASE_ROOT_PATH="${CO_SIM_MODULES_ROOT_PATH}"
export CO_SIM_PYTHONPATH=${CO_SIM_USE_CASE_ROOT_PATH}:${CO_SIM_ROOT_PATH}/site-packages:${CO_SIM_ROOT_PATH}/nest/lib/python3.8/site-packages

python3 ${CO_SIM_USE_CASE_ROOT_PATH}/main.py --global-settings ${CO_SIM_MODULES_ROOT_PATH}/EBRAINS_WorkflowConfigurations/general/global_settings.xml --action-plan ${CO_SIM_USE_CASE_ROOT_PATH}/userland/configs/local/plans/cosim_alpha_brunel_local.xml
