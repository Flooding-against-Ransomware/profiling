# Requirements

`poetry` for Python installed and available in the execution environment.

# Install dependencies

`poetry install`

# Usage

Launch `sh batch_run.sh targetFolder` 

where targetFolder is a folder containing a subfolder named "stage1" with the report files in the following format ``ransomwareName-NONE-NONE-NUMBER.json'', where 
"ransomwareName" is the name of the ransomware and "NUMBER" is the report number (1,2,3,...).

After running the script, the results are in:

- stage 3: the summary results of the single reports
- stage 4: the aggregate results of the reports, with average and st. dev.
- stage 5: donut visualisation of the results