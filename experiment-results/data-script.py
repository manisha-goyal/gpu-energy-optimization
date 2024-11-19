import os
import csv
import numpy as np
import pandas as pd

def check_accelwattch_logs(dataframe, subdirectory_path, chip, freq):
    """

    Parameters:
    - dataframe (pd.DataFrame): DataFrame containing the applications.
    - subdirectory_path (str): Base path of the subdirectories.
    - chip (str): Chip name to be included in the path.

    Returns:
    - pd.DataFrame: Updated DataFrame with a new column 'log_exists' indicating the presence of the log file.
    """
    # Ensure the Application column exists
    if 'Application' not in dataframe.columns:
        raise ValueError("DataFrame must contain a column named 'Application'")
    extracted_df = pd.DataFrame(columns = [
                                    "Application", 
                                    "gpu_avg_TOT_INST", 
                                    "gpu_tot_avg_power", 
                                    "gpu_avg_FPUP", 
                                    "gpu_avg_IDLE_COREP",
                                    "kernel_avg_power",
                                    "gpu_avg_CONSTP",
                                    "gpu_avg_RFP",
                                    "gpu_avg_STATICP",
                                    "gpu_avg_DRAMP",
                                    "gpu_avg_INTP",
                                    "gpu_avg_SCHEDP",
                                    "gpu_avg_L2CP",
                                    "gpu_avg_SHRDP"
                                ])

    for application in dataframe['Application']:
        # Construct the path to check
        path1 = os.path.join(subdirectory_path, application, f"{chip}-Accelwattch_SASS_SIM", "accelwattch_power_report.log")
        path2 = os.path.join(subdirectory_path, application, f"{chip}-Accelwattch_SASS_SIM-{freq}MHZ", "accelwattch_power_report.log")
        # Check if the log file exists

        if os.path.exists(path1):
            log_path = path1
        elif os.path.exists(path2):
            log_path = path2
        
        if os.path.exists(log_path):
            #print(log_path)
            with open(log_path, "r") as log_file:
                # Read lines from the file
                lines = log_file.readlines()
                
                # Start processing from the bottom
                gpu_avg_TOT_INST = None
                gpu_tot_avg_power = None
                gpu_avg_FPUP = None
                found_kernel_launch_uid = False
                gpu_avg_IDLE_COREP = None
                kernel_avg_power = None
                gpu_avg_CONSTP = None
                gpu_avg_RFP = None
                gpu_avg_STATICP = None
                gpu_avg_DRAMP = None
                gpu_avg_INTP = None
                gpu_avg_SCHEDP = None
                gpu_avg_L2CP = None
                gpu_avg_SHRDP = None
                for line in reversed(lines):
                    if "kernel_launch_uid" in line:
                        found_kernel_launch_uid = True
                        break  # Stop reading further once kernel_launch_uid is found
                    
                    if "gpu_avg_TOT_INST" in line:
                        gpu_avg_TOT_INST = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_tot_avg_power" in line:
                        gpu_tot_avg_power = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_FPUP" in line:
                        gpu_avg_FPUP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_IDLE_COREP" in line:
                        gpu_avg_IDLE_COREP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "kernel_avg_power" in line:
                        kernel_avg_power = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_CONSTP" in line:
                        gpu_avg_CONSTP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_RFP" in line:
                        gpu_avg_RFP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_STATICP" in line:
                        gpu_avg_STATICP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_DRAMP" in line:
                        gpu_avg_DRAMP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_INTP" in line:
                        gpu_avg_INTP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_SCHEDP" in line:
                        gpu_avg_SCHEDP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_L2CP" in line:
                        gpu_avg_L2CP = float(line.split('=')[-1].strip().replace(',', ''))
                    elif "gpu_avg_SHRDP" in line:
                        gpu_avg_SHRDP = float(line.split('=')[-1].strip().replace(',', ''))

                # Only add data if kernel_launch_uid is found
                if found_kernel_launch_uid:
                    temp_df = pd.DataFrame([{
                        "Application": application,
                        "gpu_avg_TOT_INST": gpu_avg_TOT_INST,
                        "gpu_tot_avg_power": gpu_tot_avg_power,
                        "gpu_avg_FPUP": gpu_avg_FPUP,
                        "gpu_avg_IDLE_COREP": gpu_avg_IDLE_COREP,
                        "kernel_avg_power": kernel_avg_power,
                        "gpu_avg_CONSTP": gpu_avg_CONSTP,
                        "gpu_avg_RFP": gpu_avg_RFP,
                        "gpu_avg_STATICP": gpu_avg_STATICP,
                        "gpu_avg_DRAMP": gpu_avg_DRAMP,
                        "gpu_avg_INTP": gpu_avg_INTP,
                        "gpu_avg_SCHEDP": gpu_avg_SCHEDP,
                        "gpu_avg_L2CP": gpu_avg_L2CP,
                        "gpu_avg_SHRDP": gpu_avg_SHRDP
                    }])
                    extracted_df = pd.concat([extracted_df, temp_df], ignore_index=True)

    # Add the result to the dataframe
    
    return extracted_df

def get_csv_data(filepath):
    all_stats = {}
    apps = []
    data = {}
    any_data = False
    with open(filepath, 'r') as data_file:
        reader = csv.reader(data_file)  # define reader object
        state = "start"
        for row in reader:  # loop through rows in csv file
            if len(row) != 0 and row[0].startswith("----"):
                state = "find-stat"
                continue
            if state == "find-stat":
                current_stat = row[0]
                state = "find-apps"
                continue
            if state == "find-apps":
                apps = [item.upper() for item in row[1:]]
                state = "process-cfgs"
                continue
            if state == "process-cfgs":
                if len(row) == 0:
                    if any_data:
                        all_stats[current_stat] = apps, data
                    apps = []
                    data = {}
                    state = "start"
                    any_data = False
                    continue
                temp = []
                for x in row[1:]:
                    try:
                        temp.append(float(x))
                        any_data = True
                    except ValueError:
                        temp.append(0)
                data[row[0]] = np.array(temp)

    return all_stats

def generate(data_dict):
    dataframe_columns = list(data_dict.keys()) + ['Application']
    dataframe = pd.DataFrame(columns=dataframe_columns)

    # Process the dictionary
    for key, (apps, values) in data_dict.items():
        for application_name, value in values.items():
            scalar_value = value.item() if isinstance(value, np.ndarray) and value.size == 1 else value
            # If the application name already exists in the DataFrame, update its row
            if application_name in dataframe['Application'].values:
                dataframe.loc[dataframe['Application'] == application_name, key] = value
            else:
                # Create a new row for the application name
                new_row = {col: None for col in dataframe_columns}
                new_row['Application'] = application_name
                new_row[key] = scalar_value
                dataframe = pd.concat([dataframe, pd.DataFrame([new_row])], ignore_index=True)


    # Fill any missing values with 0 or NA, if needed
    #dataframe.fillna(0, inplace=True)
    columns = ['Application'] + [col for col in dataframe.columns if col != 'Application']
    dataframe = dataframe[columns]
    # Save the DataFrame to a CSV file
    #dataframe.to_csv('output.csv', index=False)
    return dataframe


def process_experiment_results(base_directory):
    # Loop through each subdirectory in the base directory
    for subdirectory in os.listdir(base_directory):
        if subdirectory.startswith('.'):
            continue
        chip = subdirectory.split("_")[1].split("-")[0]
        freq = subdirectory.split("_")[1].split("-")[1].split(".")[0]
        subdirectory_path = os.path.join(base_directory, subdirectory)
        #print(chip)
        # Check if it's a directory
        if os.path.isdir(subdirectory_path):
            # Construct the CSV file name
            csv_file = f"{subdirectory}.csv"
            csv_path = os.path.join(subdirectory_path, csv_file)
            
            # Check if the CSV file exists
            if os.path.exists(csv_path):
                print(f"Processing: {csv_path}")
                # Process the CSV file
                all_stats = get_csv_data(csv_path)
                print(type(all_stats))
                # Optional: Convert the stats to a DataFrame for further analysis
                #for stat, (apps, data) in all_stats.items():
                 #   df = pd.DataFrame(data, index=apps)
                  #  output_file = os.path.join(subdirectory_path, f"{stat}_output.csv")
                   # df.to_csv(output_file)
                    #print(f"Saved: {output_file}")
                dataframe = generate(all_stats)
                dataframe['Application'] = dataframe['Application'].str.replace('--final_kernel', '', regex=False)
                applications = dataframe['Application']
                #dataframe.to_csv(f"{subdirectory_path}/output_{subdirectory}.csv", index=False)
                #print(applications)
                df = check_accelwattch_logs(applications.to_frame(), subdirectory_path, chip, freq)
                result_df = dataframe.merge(df, on="Application", how="left")
                #print(result_df)
                result_df.to_csv(f"{subdirectory_path}/output_{subdirectory}.csv", index=False)
            else:
                print(f"CSV file not found: {csv_path}")

# Set the base directory for experiment results
base_directory = "experiment-results/"  # Replace with your base directory path

# Process the experiment results
process_experiment_results(base_directory)
