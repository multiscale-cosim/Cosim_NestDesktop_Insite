import nest

nest.ResetKernel()

nest.SetKernelStatus({
    "data_path": "/nest/",
    "overwrite_files": True,
    "print_time": True,
    "resolution": 0.1
})

n_params = {
    "V_m": 0,
    "E_L": 0,
    "C_m": 250,
    "tau_m": 2,
    "V_th": 20,
    "V_reset": 0,
    "tau_syn_ex": 0.5,
    "tau_syn_in": 0.5,
    "I_e": 0,
    "V_min": 0
}

nb_neurons = 100
total_inhibitory_neurons = 25

nodes_ex = nest.Create('iaf_psc_alpha', nb_neurons, n_params)
nodes_in = nest.Create('iaf_psc_alpha', total_inhibitory_neurons, n_params)

noise = nest.Create('poisson_generator', params={"rate": 8895})

espikes = nest.Create('spike_recorder', params={"label": "brundel-py-ex", "record_to": "ascii"})
ispikes = nest.Create('spike_recorder', params={"label": "brundel-py-in", "record_to": "ascii"})

nest.CopyModel("static_synapse", "excitatory", params={"weight": 20.7, "delay": 1.5})
nest.CopyModel("static_synapse", "inhibitory", params={"weight": 103.4, "delay": 1.5})

nest.Connect(nodes_ex, nodes_ex + nodes_in, conn_spec={"rule": "fixed_indegree", "indegree": 10}, syn_spec="excitatory")
nest.Connect(nodes_in, nodes_ex + nodes_in, conn_spec={"rule": "fixed_indegree", "indegree": 10}, syn_spec="inhibitory")

nest.Connect(noise, nodes_ex)
nest.Connect(noise, nodes_in)

nest.Connect(nodes_in[:50], espikes)
nest.Connect(nodes_in[:25], ispikes)

# Co-Simulation Devices

input_to_simulator = nest.Create('spike_generator', nb_neurons, params={"stimulus_source": "mpi", "label": "/../transformation/spike_generator"})
output_from_simulator = nest.Create('spike_recorder', 1, params={"record_to": "mpi", "label": "/../transformation/spike_recorder"})

nest.Connect(input_to_simulator, nodes_ex, conn_spec="one_to_one", syn_spec={"weight": 20.7, "delay": 0.1})
nest.Connect(nodes_ex, output_from_simulator, conn_spec="all_to_all")

nest.Prepare()
