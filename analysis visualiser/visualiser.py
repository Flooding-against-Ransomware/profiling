import numpy as np
import matplotlib.pyplot as plt
import matplotlib
import json

matplotlib.rcParams['text.usetex'] = True
matplotlib.rcParams['text.latex.preamble'] = '\\usepackage{times}'

def sunburst(nodes, total=np.pi * 2, offset=0, level=0, ax=None):
    ax = ax or plt.subplot(111, projection='polar')

    if level == 0:
        label = nodes[ "label" ]
        value = nodes[ "value" ]
        subnodes = nodes[ "subnodes" ]
        ax.bar([0], [0.5], [np.pi * 2], color="white")
        ax.text(0, 0, label, fontsize=15, ha='center', va='center')
        sunburst(subnodes, total=value, level=level + 1, ax=ax)
    elif nodes:
        d = np.pi * 2 / total
        labels = []
        widths = []
        local_offset = offset
        print( nodes )
        for node in nodes:
            label = node[ "label" ]
            value = node[ "value" ]
            subnodes = node[ "subnodes" ]
            labels.append(label)
            widths.append(value * d)
            sunburst(subnodes, total=total, offset=local_offset,
                     level=level + 1, ax=ax)
            local_offset += value
        values = np.cumsum([offset * d] + widths[:-1])
        heights = ( [1] if level == 1 else [-.20] ) * len(nodes)
        bottoms = np.zeros(len(nodes)) + level - 0.5
        rects = ax.bar(values, heights, widths, bottoms, linewidth=1,
                       edgecolor='black', align='edge', color=[(.5, .5, .5, 0.25),(.5, .5, .5, 0.5)])
        for rect, label, node in zip(rects, labels, nodes):
            x = rect.get_x() + rect.get_width() / 2
            y = rect.get_y() + rect.get_height() / 2
            rotation = (90 + (360 - np.degrees(x) % 180)) % 360
            fontsize = ( max(6, (min(12,5*node["value"]))) if level == 1 else 6 )
            if( node["value"] > 1 ):
                ax.text(x, y, label, color="black", fontsize=fontsize, rotation=rotation, ha='center', va='center') 

    if level == 0:
        ax.set_theta_direction(-1)
        ax.set_theta_zero_location('N')
        ax.set_axis_off()

with open( "_result.json" ) as data:
    data = json.load( data )
    path = data.pop( "path" )
    for key, value in data.items():
        sunburst( value )
        plt.savefig( f"{path}_{key}.pdf" )
        plt.clf()