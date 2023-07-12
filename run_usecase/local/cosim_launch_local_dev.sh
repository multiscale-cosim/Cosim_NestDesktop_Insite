killall -9 python3
killall -9 mpirun

export CO_SIM_ROOT_PATH="/home/vagrant/multiscale-cosim/my_forks"
export CO_SIM_MODULES_ROOT_PATH="${CO_SIM_ROOT_PATH}/Cosim_NestDesktop_Insite"
export CO_SIM_USE_CASE_ROOT_PATH="${CO_SIM_MODULES_ROOT_PATH}"
export CO_SIM_PYTHONPATH=/home/vagrant/multiscale-cosim/my_forks/Cosim_NestDesktop_Insite:/home/vagrant/multiscale-cosim/site-packages:/home/vagrant/multiscale-cosim/nest/lib/python3.8/site-packages

rm -r /home/vagrant/multiscale-cosim/my_forks/Cosim_NestDesktop_Insite/result_sim

python3 ../../main.py --global-settings ../../EBRAINS_WorkflowConfigurations/general/global_settings.xml --action-plan ../../userland/configs/local/plans/cosim_alpha_brunel_local.xml
