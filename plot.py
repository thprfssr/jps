import numpy as np
from matplotlib import pyplot as plt
from matplotlib import animation
import pandas as pd

filename = 'smol.tsv'
df = pd.read_csv(filename, sep = '\t')
times = list(set(df['t']))
pids = list(set(df['id']))
times.sort()
pids.sort()

def get_particle_state(pid, t):
    filtered = df.loc[(df['t'] == t) & (df['id'] == pid)]
    rx = sum(filtered['rx']) # We sum because there is only one row in the
    ry = sum(filtered['ry']) # filtered data, and we need to convert that
    rz = sum(filtered['rz']) # single row to a scalar, and also because
    vx = sum(filtered['vx']) # I'm tired.
    vy = sum(filtered['vy'])
    vz = sum(filtered['vz'])
    return rx, ry, rz, vx, vy, vz

fig = plt.figure()
ax = plt.axes(projection = '3d')

X, Y, Z = [], [], []
t = times[-1]
for p in pids:
    rx, ry, rz, vx, vy, vz = get_particle_state(p, t)
    X.append(rx)
    Y.append(ry)
    Z.append(rz)

#ax.plot_trisurf(X, Y, Z)
ax.scatter(X, Y, Z)
plt.show()

