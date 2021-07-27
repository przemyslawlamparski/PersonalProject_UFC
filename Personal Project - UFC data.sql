-- PERSONAL PROJECT
-- ANALYSIS OF UFC DATA FOR THE PERIOD OF March, 1994 - March, 2021
-- v0.01 27/07/2021

-- Let's explore the data, find out fighter's most basic statistics - Wins | Loses | Draws | Win % | Loss %

WITH W AS (         --Let's Create list of all fight's and it's winner. Gonna save it as view vwWinners as well for further refference
SELECT 
R_FIGHTER,
B_FIGHTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
UNION ALL SELECT
B_FIGHTER AS R_FIGHTER,
R_FIGHTER AS B_FIGTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
), W_N AS           --Counting Wins/Loses/Draws for 5 figters with most wins
(
SELECT TOP 5 WITH TIES
R_FIGHTER AS Fighter,
COUNT(CASE WHEN WINNER = R_FIGHTER THEN 1 END) AS Wins,
COUNT(CASE WHEN WINNER = B_FIGHTER THEN 1 END) AS Loses,
COUNT(CASE WHEN WINNER = 'DRAW' THEN 1 END) AS Draws
FROM W
GROUP BY R_FIGHTER
ORDER BY WINS DESC
)                     --Adding some more Details
SELECT
Fighter,
Wins,
Loses,
Draws,
CAST(((wins * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(4,2)) AS 'Prc Won',
CAST(((Loses * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(4,2)) AS 'Prc lost'
FROM W_N

--It clearly appears that the Coloradan Cowboy has scored most wins in the UFC history, but can he be considered the most accomplished fighter?
--Let's leave it for a moment

-- Now, it's time to find out who has the best Win-Loss ratio
WITH WR AS (
SELECT
R_FIGHTER,
COUNT(CASE WHEN WINNER = R_FIGHTER THEN 1 END) AS Wins,
COUNT(CASE WHEN WINNER = B_FIGHTER THEN 1 END) AS Loses,
COUNT(CASE WHEN WINNER = 'DRAW' THEN 1 END) AS Draws
FROM vwWinners
GROUP BY R_FIGHTER
HAVING (COUNT(CASE WHEN WINNER = R_FIGHTER THEN 1 END) + COUNT(CASE WHEN WINNER = B_FIGHTER THEN 1 END) + COUNT(CASE WHEN WINNER = 'DRAW' THEN 1 END)) > 10
)
SELECT TOP 5 WITH TIES
R_FIGHTER AS Fighter,
(WINS + Loses + DRAWS) AS 'Total Fights',
Wins,
Loses,
Draws,
CAST(((wins * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(10,2)) AS 'Prc Won'
--CAST(((Loses * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(4,2)) AS 'Prc lost'
FROM WR
GROUP BY wr.R_FIGHTER,WR.wins, wr.loses, wr.draws
HAVING (WINS + LOSES + DRAWS) >10
ORDER BY [Prc Won] DESC
-- Obviously, It's Kamaru Usman and Khabib Nurmagomedov who won all their fights so far!
-- And since Khabib has decided to retire with 29/0 (13/0 in UFC) record, we can assume that The Nigerian Nightmare is the TOP OF THE TOP right now.

-- Now, let's find out who has the longest winning streak in the UFC
WITH L AS (                                     
SELECT                                          
[DATE], 
R_FIGHTER,
B_FIGHTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
UNION ALL SELECT
[DATE],
B_FIGHTER AS R_FIGHTER,
R_FIGHTER AS B_FIGTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
), M AS (
SELECT 
[DATE],
R_FIGHTER,
B_fighter,
winner,
SUM(CASE WHEN winner <> R_fighter THEN 1 END)   -- starts with null, ADD +1 when Fighter loses - streak bronken
OVER (PARTITION by R_FIGHTER ORDER BY [date] ) TMP
FROM L) 
SELECT
R_FIGHTER,
COUNT(*) AS STREAK
FROM M
WHERE R_fighter = WINNER                           -- List of consecutive win streaks of each fighter
group BY R_fighter, TMP                         
ORDER BY STREAK DESC
-- It's Anderson Silva! Even though lately he's having some rough time, being undefited for 16 consecutive fights is something clearly out of this world.

