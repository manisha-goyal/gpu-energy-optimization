import pandas as pd
import os


base_directory = os.getcwd()

# Get all files in the directory that start with 'output'
output_files = [f for f in os.listdir(base_directory) if f.startswith('output') and os.path.isfile(os.path.join(base_directory, f))]
# Printing the first few rows of each DataFrame to verify

GPU = []
frequency = []

# Extract GPU and frequency for each string
for file_name in output_files:
    # Split the string by '-' and '.'
    parts = file_name.split('-')
    # Extract GPU name and frequency
    GPU.append(parts[0].split('_', 1)[-1])  # Extract GPU name (e.g., TITANX)
    frequency.append(parts[1].split('.')[0]) 

dfs = []

for i in range(len(output_files)):
    # Read the CSV into a DataFrame
    df = pd.read_csv(output_files[i])
    
    # Add new columns GPU and freq with the same number of rows as the dataframe
    df.insert(0, "GPU", [GPU[i]] * len(df['Application']))
    df.insert(1, "Frequency", [frequency[i]] * len(df['Application']))
    
    # Append the modified DataFrame to the list
    dfs.append(df)

#print(GPU)
#print(frequency)
combined_df = pd.concat(dfs, ignore_index=True)
output_file = f"{GPU[0]}.xlsx"
combined_df.to_excel(output_file, index=False)