from mpi4py import MPI
from glob import glob
import math
from scipy.io import netcdf
from scipy.io import savemat
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

files = glob('/compyfs/xudo627/e3sm_scratch/CLMMOS_USRDAT_Global_inund.2020-09-10-083619/run/*.mosart.h0*.nc')
files = sorted(files)
print(len(files))
files = files[int(len(files)/2):]
N = len(files)
num_files_per_rank = math.ceil(len(files)/size)

if rank + 1 == size:
	files = files[rank*num_files_per_rank :]
else:
	files = files[rank*num_files_per_rank : (rank+1)*num_files_per_rank]

#print('total number of files is ' + str(N) + ', num_files_per_rank = ' + str(num_files_per_rank))
#print('rank = ' + str(rank) + ', numer of files to read is ' + str(len(files)))

comm.Barrier()

# pre-allocate array
qsur = np.zeros((360,720,len(files)))
frac = np.zeros((360,720,len(files)))
yr   = np.zeros((len(files,)))
mo   = np.zeros((len(files,)))
da   = np.zeros((len(files,)))
for i in range(len(files)):
	if rank == 1:
		print('[rank = ' + str(rank) + ']. [' + str(round((i+1)/len(files)*100,1)) + '%]: ' + files[i])
	filename = files[i].split('/')
	filename = filename[6]
	filestrs = filename.split('.')
	datestrs = filestrs[4]
	datestrs = datestrs.split('-')
	yr[i]    = int(datestrs[0])
	mo[i]    = int(datestrs[1])
	da[i]    = int(datestrs[2])

	f = netcdf.netcdf_file(files[i], mmap = False, 'r')
	qsur[:,:,i] = np.nanmean(f.variables['QSUR_LIQ'][:],           axis=0)
	frac[:,:,i] = np.nanmean(f.variables['FLOODPLAIN_FRACTION'][:],axis=0)
	if i == 0:
		lon = f.variables['lon'][:]
		lat = f.variables['lat'][:]
	f.close()


mdic = {'qsur': qsur, 'frac': frac, 'lat': lat, 'lon': lon, 'yr': yr, 'mo': mo, 'da': da}		
if rank < 10:
	fname = 'data/Global_inund_mosart0' + str(rank) + '.mat'
else:
	fname = 'data/Global_inund_mosart'  + str(rank) + '.mat'
savemat(fname, mdic)

#print(rank)