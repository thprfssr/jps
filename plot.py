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


N = len(df) // 110
STATES = [None] * N
for i in range(N):
    STATES[i] = df.iloc[i*110 : i*110 + 109]

def get_particle_state(pid, i):
    filtered = STATES[i].loc[df['id'] == pid]
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
    X = np.array([get_particle_state(p, i)[0] for p in pids])
    Y = np.array([get_particle_state(p, i)[1] for p in pids])
    Z = np.array([get_particle_state(p, i)[2] for p in pids])

    sct.set_data(X, Y)
    sct.set_3d_properties(Z)


    print(i)

    return sct


ax.set_xlim(-6,6)
ax.set_ylim(-6,6)
ax.set_zlim(-12,12)

ani = animation.FuncAnimation(
        fig, animate, 1000)
#plt.show()
ani.save('test.mp4')

