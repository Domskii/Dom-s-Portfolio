# Insurance Data analysis

In this notebook, we're going to conduct analysis on insurance data. This [dataset](https://github.com/Domskii/Data_analysis_Portfolio/blob/main/Insurance%20Dataset/CREATE%2BInsurance%2BDatabase%20(1).sql) is modelled in a very complicated way to reflect real-life data analytics environment in a financial industry. Database diagram is [here](https://github.com/Domskii/Data_analysis_Portfolio/blob/main/Insurance%20Dataset/Insurance%2BDatabase%2BDiagram%2B-%2BAnnotated%20(1).pdf)

At our insurance company, the examiners (aka claim specialists) are tasked with regularly using the Reserving Tool to help them estimate how much a given claim is going to cost the company.  There are lots of guidelines on how frequently an examiner should be using the Reserving Tool. An examiner has to use the reserving tool a certain number of days after the claim re-opens, after being assigned the claim, or after an examiner last used the Reserving Tool on that claim.

Our job is to determine how long an examiner has until they are required to use the Reserving Tool, and if they are already past their due date, how many days they have been overdue.  And we will need to do this for all the claims assigned to all of our examiners.

The purpose of this project is to create a Stored Procedure that retrieves all the relevant information from complex data model.

SQL CODE is [here](https://github.com/Domskii/Data_analysis_Portfolio/blob/main/Insurance%20Dataset/Insurance.sql)
