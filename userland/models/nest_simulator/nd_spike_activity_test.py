import numpy

def configure_nest(nest):

  nest.ResetKernel()

  # Set simulation kernel
  nest.SetKernelStatus({
    "local_num_threads": 1,
    "resolution": 0.1,
    "rng_seed": 1
  })

  # Create nodes
  pg1 = nest.Create("poisson_generator", 1, params={
    "rate": 6500,
  })
  n1 = nest.Create("iaf_psc_alpha", 100)
  sr1 = nest.Create("spike_recorder", 1)

  # Connect nodes
  nest.Connect(pg1, n1, syn_spec={ 
    "weight": 10,
  })
  nest.Connect(n1, sr1)

  input_to_simulator = []
  output_from_simulator = []

  # Prepare simulation
  nest.Prepare()

  return input_to_simulator, output_from_simulator


