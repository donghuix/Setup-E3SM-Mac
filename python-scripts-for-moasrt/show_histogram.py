from mpi4py import MPI
from glob import glob
from scipy.io import loadmat

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

files = glob('data/Global_')