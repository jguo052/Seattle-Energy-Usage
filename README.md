# Seattle-Energy-Usage

## Goal
The goal of this analysis project is to identify buildings in Seattle, Washington that perform poorly in terms of energy usage. The focus will be on investigating energy usage for buildings with similar purposes.

## Data
The data was found on [data.seattle.gov](https://data.seattle.gov/dataset/2015-Building-Energy-Benchmarking/h7rm-fz6m) and was cleaned in Excel. The cleaned data can be found in the [data folder](https://github.com/jguo052/Seattle-Energy-Usage/tree/main/Public%20Data) within this repository.

## Conclusions
[The PostgreSQL code behind the conclusions can be found here](https://github.com/jguo052/Seattle-Energy-Usage/blob/main/energy_analysis.sql). Residential buildings, primarily low-rise, are the most numerous energy users in Seattle. There is decent opportunity to reduce energy use over the long term if steps were taken to improve energy efficiency within homes.

Hospitals (by far), restaurants, and supermarkets also offer great potential for lowering energy usage. These would likely be simpler to improve because there are far fewer of these buildings and changes can be more targeted. For example, buildings like the Virginia Mason Medical Center or Salty's Restaurant could be could be examined and offered recommendations due to their low performance.
