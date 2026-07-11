# Description
This project hosts a pre-processing pipeline using dbt and azure for the power bi analysis. 

The dbt marts have been verified to connect directly to Power BI from Azure
SQL (via Microsoft Entra ID authentication), confirming the report can be
rebuilt entirely against the cloud pipeline. The shipped `.pbix` still reads
from the CSV exports in `notebooks/power_bi_exports/`, since anyone opening
the file won't have access to the author's Azure credentials.