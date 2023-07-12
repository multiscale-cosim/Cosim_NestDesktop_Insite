import numpy

def configure_nest(nest, addresses):
  nest.ResetKernel()

  # Set simulation kernel
  nest.SetKernelStatus({
    # "data_path": "",
    "local_num_threads": 1,
    "resolution": 0.1,
    "rng_seed": 1,
  })

  # Create nodes
  n1 = nest.Create("iaf_psc_alpha", 1)
  n2 = nest.Create("iaf_psc_alpha", 1)

  # Connect nodes
  nest.Connect(n1, n2)

  input_stimulator = nest.Create("spike_generator", params={
    "mpi_address": addresses['stimulus_source'],
    "stimulus_source": "mpi",
  })
  nest.Connect(input_stimulator, n1)

  output_recorder = nest.Create("spike_recorder", params={
    "mpi_address": addresses['record_to'],
    "record_to": "mpi",
  })
  nest.Connect(n2, output_recorder)

  # Prepare simulation
  nest.Prepare()

  return input_stimulator, output_recorder 