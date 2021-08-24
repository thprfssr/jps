import numpy as np
from matplotlib import pyplot as plt
from matplotlib import animation
import pandas as pd

filename = 'output.tsv'
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
#ax = plt.axes(projection = '3d')
ax = fig.add_subplot(111, projection = '3d')
sct, = ax.plot([], [], [], 'o', markersize=2)

#line, = ax.plot([], [], 'o')

'''
X, Y, Z = [], [], []
t = times[-1]
for p in pids:
    rx, ry, rz, vx, vy, vz = get_particle_state(p, t)
    X.append(rx)
    Y.append(ry)
    Z.append(rz)

#ax.plot_trisurf(X, Y, Z)
#ax.scatter(X, Y, Z)
#plt.show()
'''

def animate(i):
    t = times[i]
    X = np.array([get_particle_state(p, t)[0] for p in pids])
    Y = np.array([get_particle_state(p, t)[1] for p in pids])
    Z = np.array([get_particle_state(p, t)[2] for p in pids])

    sct.set_data(X, Y)
    sct.set_3d_properties(Z)
    return sct


ax.set_xlim(-6,6)
ax.set_ylim(-6,6)
ax.set_zlim(-12,12)

ani = animation.FuncAnimation(
        fig, animate, 300)
#plt.show()
ani.save('test.mp4')

