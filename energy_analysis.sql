------------------ GOAL ------------------
-- The goal of this analysis project is to identify buildings that
-- perform poorly in terms of energy usage. The focus will be on 
-- investigating energy usage for buildings with similar purposes.


-- Distribution of each building's primary use
SELECT 
	primary_use,
	COUNT(*) 
FROM Public."Building_Info"
GROUP BY primary_use
ORDER BY 2 DESC;
-- The most numerous building use in the dataset is
-- multifamily housing at 1649 rows (nearly half the data)
-- followed by offices at 485.


-- Distribution of each building's property type
SELECT 
	property_type,
	COUNT(*) 
FROM Public."Building_Info"
GROUP BY property_type
ORDER BY 2 DESC;
-- Breaking this down further, 998 low-rise multifamily, 539 mid-rise
-- and 297 small- and mid-sized offices


-- Entries with property type listed as "Other" provide more specific services
-- (police station, library, fitness centers, automobile dealership)
SELECT primary_use FROM Public."Building_Info"
WHERE property_type = 'Other';


-- Average energy usage by property type
SELECT property_type,
	AVG(site_eui) AS avg_site_eui,
	AVG(source_eui) avg_source_eui,
	COUNT(*) num_property
FROM Public."Building_Info" b
JOIN Public."Energy" e
	ON b.building_id = e.building_id
GROUP BY 1
ORDER BY 3 DESC;
-- The heaviest energy users (adjusted for building size) are:
-- 		supermarkets (612 kbtu/sqft),
-- 		laboratories (583 kbtu/sqft),
-- 		hospitals (411 kbtu/sqft),
-- 		and restaurants (319 kbtu/sqft)
-- Supermarkets and hospitals are generally very large buildings.
-- For these metrics to be large even after dividing by the size
-- means supermarkets and hospitals use massive amounts of energy.
-- There is only a single laboratory contributing 583 kbtu/sqft.


-- Look at total EUI (kbtu/sqft) across different property types
SELECT property_type,
	SUM(source_eui) total_eui,
	AVG(source_eui) avg_eui,
	COUNT(*) num_property
FROM Public."Building_Info" b
JOIN Public."Energy" e
	ON b.building_id = e.building_id
GROUP BY 1
ORDER BY 2 DESC;
-- Total EUI is the largest across residential buildings, by far.
-- In a way, has the largest potential for reducing Seattle EUI.
-- Largest total EUI:
-- 		Low-rise multifamily (86k kbtu/sqft),
-- 		Other (63k kbtu/sqft), 
-- 		Mid-rise multifamily (51k kbtu/sqft),
-- 		Small- and mid-sized offices (48k kbtu/sqft)


-- Determining the least efficient buildings within each property type.
-- Create a CTE with each buildings EUI ranking (1 being worst EUI score)
WITH eui_rankings AS (SELECT 
	l.property_name,
	b.property_type,
	b.primary_use,
	e.source_eui,
	RANK() OVER (PARTITION BY b.property_type ORDER BY e.source_eui DESC) AS eui_rank
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON b.building_id = l.building_id
	JOIN Public."Energy" e
	ON b.building_id = e.building_id
WHERE source_eui IS NOT NULL),

-- Create another CTE with average EUI to compare with each building's EUI
averages AS (SELECT
	b.property_type,
	AVG(e.source_eui) AS source_eui_avg
FROM Public."Building_Info" b
JOIN Public."Energy" e
	ON b.building_id = e.building_id
GROUP BY 1)

-- Join the two CTEs and only examine worst three buildings
-- from each property type
SELECT er.*, a.source_eui_avg
FROM eui_rankings er
	JOIN averages a
	ON er.property_type = a.property_type
WHERE eui_rank < 4;
-- All of these buildings significantly exceed the average EUI
-- within their respective property type.
-- A few buildings whose EUI score is much worse than the runner up:
-- 		South Seattle Distribution Center
--		Hotel Max
-- 		Fisher Plaza - West Building (Primarily Parking)
-- 		Saltys Restaurant 
-- 		Ballard Care & Rehab (Senior Care)



-- Investigate green house gas emissions (GHG)
-- and identify the worst polluters
SELECT
	b.property_type,
	AVG(e.ghg) avg_ghg_emissions,
	AVG(e.ghg_per_sqft) avg_ghg_per_sqft
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON l.building_id = b.building_id
	JOIN Public."Energy" e
	ON l.building_id = e.building_id
GROUP BY 1
ORDER BY 3 DESC;
-- Hospitals produce 10x more green house gas emissions on average
-- (before accounting for building size) than the other property types.
-- When accounting for building size, restaurants become quite
-- comparable emitors to hospitals.
-- The next largest emitors are supermarkets.



-- "Restaurant" text in the property_type column was not clean.
-- Updated the table accordingly to remove trailing white space.
UPDATE Public."Building_Info"
SET property_type = 'Restaurant'
WHERE property_type LIKE 'Rest%';



-- Query for specific buildings that emit the most GHGs within the
-- hospital, restaurant, and supermarket categories.
-- Create a CTE to generate GHG emission rankings by building
WITH ghg_rankings AS (SELECT 
	l.property_name,
	b.property_type,
	e.ghg,
	e.ghg_per_sqft,
	RANK() OVER (PARTITION BY b.property_type ORDER BY e.ghg_per_sqft DESC) AS ghg_per_sqft_rank
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON b.building_id = l.building_id
	JOIN Public."Energy" e
	ON b.building_id = e.building_id
WHERE e.ghg_per_sqft IS NOT NULL
	AND b.property_type IN ('Hospital', 'Restaurant', 'Supermarket/Grocery Store'))

-- Query the GHG rankings CTE to show top three emitors
-- from the hospital, restaurant, and supermarket categories
SELECT 
	property_name,
	property_type,
	ghg,
	ghg_per_sqft
FROM ghg_rankings
WHERE ghg_per_sqft_rank < 4;
-- Virginia Mason (Hospital) emits slightly more than other hospitals.
-- Salty's Restaurant and Pier 57 Bay Pavillion emit significantly more
-- green house gases than other restaurants in our dataset.
-- There are no serious outliers for the supermarkets category.



-- Examine total and average energy usage within each neighborhood
-- Note: not by building size
SELECT
	l.neighborhood,
	SUM(e.site_energy_use) total_energy_use,
	ROUND(AVG(e.site_energy_use)) avg_per_building
FROM Public."Location" l
JOIN Public."Energy" e
	ON l.building_id = e.building_id
GROUP BY 1
ORDER BY 3 DESC;
-- Downtown has the highest average energy use.
-- Lake Union, where numerous tech offices are located, comes second.
-- East Seattle and Northeast are the next largest users.


-- Total energy use for each property type within each neighborhood.
SELECT
	l.neighborhood,
	b.property_type,
	ROUND(SUM(e.site_energy_use)) total_energy_use
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON l.building_id = b.building_id
	JOIN Public."Energy" e
	ON l.building_id = e.building_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Determine the property type that uses the most energy
-- within each neighborhood
-- Create a CTE of energy usage by neighborhood and property type
WITH neighborhood_property_type AS
(SELECT
	l.neighborhood,
	b.property_type,
	ROUND(SUM(e.site_energy_use)) total_energy_use
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON l.building_id = b.building_id
	JOIN Public."Energy" e
	ON l.building_id = e.building_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC),

-- Create a CTE of rankings by total energy use
rankings AS (SELECT 
	*,
	RANK() OVER (PARTITION BY neighborhood ORDER BY total_energy_use DESC) energy_rank
FROM neighborhood_property_type)

-- Select the property type with the largest energy use
-- within each neighborhood
SELECT
	rankings.neighborhood,
	rankings.property_type,
	rankings.total_energy_use
FROM rankings
WHERE energy_rank = 1
ORDER BY 3 DESC;
-- Large offices in Downtown use by far the largest amount of energy
-- for any property type in any neighborhood.
-- Hospitals in East Seattle come in second, using much less energy
-- than downtown large offices.
-- Most neighborhoods with smaller energy usage have low-rise multifamily
-- building as their primary energy use.

	
-- List specific buildings ordered by energy usage within each neighborhood
SELECT
	l.property_name,
	l.neighborhood,
	b.property_type,
	e.site_energy_use
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON l.building_id = b.building_id
	JOIN Public."Energy" e
	ON l.building_id = e.building_id
WHERE e.site_energy_use IS NOT NULL
ORDER BY 2, 4 DESC;
-- Examples of the highest energy uing buildings in some neighborhoods:
--		Swedish Medical Center (Hospital in Ballard)
--		South Seattle Community College (College in Delridge)
--		Starbucks (Sodo) Center (Large Office in Greater Duwamish)


-- Energy Star Scores (ES) rank a building's energy use among
-- similar buildings across the nation as a percentile.
-- Least energy efficient buildings receive a score of 1
-- most energy efficient buildings receive a score of 100

-- Which buildings have worst ES and energy usage intensity scores
SELECT
	l.property_name,
	b.property_type,
	e.es_score,
	e.site_eui
FROM Public."Location" l
JOIN Public."Building_Info" b
	ON l.building_id = b.building_id
	JOIN Public."Energy" e
	ON l.building_id = e.building_id
WHERE es_score IS NOT NULL
ORDER BY 3, 4 DESC
LIMIT 5;
-- The worst performing building is Hotel Max, followed by
-- Alexandria Biotech, two particular Large Offices, and Saars Market.


------------------ CONCLUSIONS ------------------
-- Residential buildings, primarily low-rise, are the most numerous
-- energy users in Seattle. There is decent opportunity to reduce
-- energy use over the long term if steps were taken to improve 
-- energy efficiency within homes.

-- Hospitals (by far), restaurants, and supermarkets also offer great
-- potential for lowering energy usage. These would likely be simpler to
-- improve because there are far fewer of these buildings and 
-- changes can be more targeted. For example, buildings like
-- the Virginia Mason Medical Center or Salty's Restaurant could be
-- could be examined and offered recommendations due to their low performance.
