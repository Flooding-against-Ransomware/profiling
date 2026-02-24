import json
import networkx as nx
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import scipy
import math
import numpy as np
from collections import defaultdict
import sys, os

def traverse_folder(folder_data, folder_path, graph, parent=None):
    """Traverse folder structure recursively"""
    pristine_count = 0
    lost_count = 0
    replica_count = 0
    total_files = 0

    graph.add_node(folder_path, node_type='folder')

    if parent:
        graph.add_edge(parent, folder_path)

    if 'files' in folder_data:
        for filename, file_info in folder_data['files'].items():
            status = file_info.get('status', 'unknown')
            total_files += status[ "lost" ] + status[ "pristine" ] + status[ "replica" ]

            file_path = f"{folder_path}/{filename}"
            graph.add_node(file_path, node_type='file')
            graph.add_edge(folder_path, file_path)

            graph.nodes[file_path]['file_status'] = status
            pristine_count += status[ "pristine" ]
            lost_count += status[ "lost" ]
            replica_count += status[ "replica" ]

    if 'folders' in folder_data:
        for subfolder_name, subfolder_data in folder_data['folders'].items():
            subfolder_path = f"{folder_path}/{subfolder_name}"
            sub_pristine, sub_lost, sub_replica, sub_total = traverse_folder(
                subfolder_data, subfolder_path, graph, folder_path
            )
            pristine_count += sub_pristine
            lost_count += sub_lost
            replica_count += sub_replica
            total_files += sub_total

    graph.nodes[folder_path]['pristine_count'] = pristine_count
    graph.nodes[folder_path]['lost_count'] = lost_count
    graph.nodes[folder_path]['replica_count'] = replica_count
    graph.nodes[folder_path]['total_files'] = total_files

    return pristine_count, lost_count, replica_count, total_files

if len(sys.argv) != 2:
    print("Usage: python tree_visualiser.py <path/to/input.json>")
    sys.exit(1)

json_file = sys.argv[1]

if not os.path.isfile(json_file):
    print(f"Error: file '{json_file}' not found.")
    sys.exit(1)

with open(json_file, 'r') as f:
        data = json.load(f)

G = nx.Graph()
root_path = data['root']

traverse_folder( data, root_path, G, parent=None)

print(f"Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
print(f"Root: {root_path}")

# Separate nodes by type
folder_nodes = [n for n, d in G.nodes(data=True) if d.get('node_type') == 'folder']
file_nodes = [n for n, d in G.nodes(data=True) if d.get('node_type') == 'file']

print(f"found #{len( folder_nodes )} folders")
print(f"found #{len( file_nodes )} files")

# Precompute folder sizes
folder_sizes = {
    n: G.nodes[n].get("total_files", 0)
    for n, d in G.nodes(data=True)
    if d.get("node_type") == "folder"
}

# find XX% largest folders
threshold_size_percentage = 0.2
threshold_top_size_percentage = 0.05
top_largest_folders = sorted(
    folder_sizes,
    key=folder_sizes.get,
    reverse=True
)[:int(threshold_size_percentage * len(folder_sizes))]
important_folders = set( sorted(
    folder_sizes,
    key=folder_sizes.get,
    reverse=True
)[:int(threshold_top_size_percentage * len(folder_sizes))] )

user_folders = { "document", "documents", "desktop", "download", "downloads", "pictures", "picture", "video", "videos" }
user_folders = { node for node in set( top_largest_folders ) if node.split('/')[-1].lower() in user_folders }
important_folders = important_folders.union( user_folders )

# top_largest_folders.add( threshold_top_size_percentage. )
# keep only the to XX% largest folders

folder_nodes = [node for node in folder_nodes if node in set( top_largest_folders ).union( important_folders ) ]

nodes_to_remove = [n for n,_ in G.nodes(data=True) if not n in folder_nodes ]
G.remove_nodes_from( nodes_to_remove )

folder_labels = {}
# important_folders.union( { os.path.join(root_path, folder) for folder in user_folders } )
# Filter folders from ROOT to n-th nesting level
for folder_node in folder_nodes:
    if folder_node == root_path:
        folder_labels[folder_node] = 'ROOT'
    else:
        if folder_node in important_folders:
            # Get the parent folder by removing the n-th component
            folder_name = folder_node.split('/')[-1]
            folder_labels[folder_node] = folder_name

G_weighted = G.copy()

max_folder_size = max(folder_sizes.values()) or 1

for u, v in G_weighted.edges():
    u_type = G_weighted.nodes[u].get("node_type")
    v_type = G_weighted.nodes[v].get("node_type")

    weight = 1.0
    if u_type == v_type: # there cannot be file-file edges

        u_index = top_largest_folders.index( u )+1
        v_index = top_largest_folders.index( v )+1

        if root_path in { u, v }:
            weight = 0.01
        else:
            weight = 0.05*math.log( u_index + v_index )
        
    else: # file-to-folder
        size = 1.0
        if u_type == "folder":
            size = folder_sizes[u]
        else:
            size = folder_sizes[v] 
        weight = 6.0/size

    G_weighted[u][v]["weight"] = weight

pos = nx.spring_layout(
    G_weighted, 
    k=1.0,              # Lower k -> nodes closer together (default is ~0.3)
    iterations=1500,    # More iterations -> better convergence
    weight='weight',    # Use edge weights
    scale=1.0,          # Lower scale = more compact (default is 1.0)
    seed=42
)

fig, ax = plt.subplots(figsize=(7,7), facecolor='white')

# Calculate total files for sizing
total_file_count = max(sum([G.nodes[n].get('total_files', 0) for n in folder_nodes]), 1)

# Draw edges
folder_edges = [(u, v) for u, v in G.edges() 
                if G.nodes[u].get('node_type') == 'folder' 
                and G.nodes[v].get('node_type') == 'folder'
                and { v, u }.issubset( folder_nodes ) ]

nx.draw_networkx_edges(G, pos, edgelist=folder_edges, 
                      alpha=0.4, width=0.4, edge_color="#000000", ax=ax)

# Draw folder nodes with colour based on file composition
for folder_node in folder_nodes:
    pristine = G.nodes[folder_node].get('pristine_count', 0)
    lost = G.nodes[folder_node].get('lost_count', 0)
    replica = G.nodes[folder_node].get('replica_count', 0)
    total = pristine + lost + replica
    
    if total > 0:
        # Calculate colour mixture (green for pristine, red for lost, blue for replicas)
        pristine_ratio = pristine / total
        lost_ratio = lost / total
        replica_ratio = replica / total
        
        r = lost_ratio
        g = pristine_ratio
        b = replica_ratio
        color = (r, g, b)
    else:
        color = (0.1, 0.1, 0.1)  # Light-grey for empty folders
    
    # Size based on file count
    file_count = G.nodes[folder_node].get('total_files', 0)
    
    size = (file_count / total_file_count) * 25000
    nx.draw_networkx_nodes(G, pos, nodelist=[folder_node],
                            node_color=[color], node_size=size, 
                            alpha=.75, ax=ax, node_shape='o',
                            edgecolors='black', linewidths=1)

# # Draw folder labels BELOW nodes in BLACK
label_pos = pos
# label_pos = {}

# for folder_node in folder_nodes:    
#     # label offset
#     x, y = pos[folder_node]
#     label_pos[folder_node] = (x, y)  # Adjust offset

bbox_props = dict(
    boxstyle="round,pad=0.2",   
    facecolor="white",          
    edgecolor="black",          
    alpha=0.8                   
)


nx.draw_networkx_labels(G, label_pos, folder_labels, font_size=6, 
                font_weight='bold', font_color='black', alpha=0.5, 
                verticalalignment='top', bbox=bbox_props, ax=ax)
ax.axis('off')
plt.tight_layout()

# Save the figure
plt.savefig(f"{os.path.splitext(json_file)[0]}.pdf", dpi=300, bbox_inches='tight', facecolor='white')