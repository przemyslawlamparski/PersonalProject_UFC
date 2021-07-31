-- PERSONAL PROJECT
-- ANALYSIS OF UFC DATA FOR THE PERIOD OF March, 1994 - March, 2021

-- Let's explore the data, find out fighter's most basic statistics - Wins | Loses | Draws | Win % | Loss %

WITH W AS (         --Let's Create list of all fight's and it's winner. Gonna save it as view vwWinners as well for further reference.
SELECT 
R_FIGHTER,
B_FIGHTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
UNION SELECT
B_FIGHTER AS R_FIGHTER,
R_FIGHTER AS B_FIGTER,
CASE
WHEN WINNER = 'BLUE' THEN B_FIGHTER
WHEN WINNER = 'RED' THEN R_FIGHTER
ELSE 'DRAW' END AS WINNER
FROM DBO.[123]
), W_N AS           --Counting Wins/Loses/Draws for 5 figters with most wins.
(
SELECT TOP 5 WITH TIES
R_FIGHTER AS Fighter,
COUNT(CASE WHEN WINNER = R_FIGHTER THEN 1 END) AS Wins,
COUNT(CASE WHEN WINNER = B_FIGHTER THEN 1 END) AS Loses,
COUNT(CASE WHEN WINNER = 'DRAW' THEN 1 END) AS Draws
FROM W
GROUP BY R_FIGHTER
ORDER BY WINS DESC
)                     --Adding some more Details.
SELECT
Fighter,
Wins,
Loses,
Draws,
CAST(((wins * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(4,2)) AS 'Prc Won',
CAST(((Loses * 1.00) / ((WINS * 1.00)+(Loses*1.00))*100) AS numeric(4,2)) AS 'Prc lost'
FROM W_N

--It clearly appears that the Coloradan Cowboy has scored most wins in the UFC history, but can he be considered the most accomplished fighter?
--Let's leave it for a moment.

-- Now, it's time to find out who has the best Win-Loss ratio.
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
-- And since Khabib has decided to retire with 29/0 (13/0 in UFC) record, we can assume that The Nigerian Nightmare is TOP OF THE TOP right now.

-- Blue side win%, Red side win%, Draw % per year since 2010
WITH C AS (
SELECT
YEAR(date) AS [year],
COUNT(CASE WHEN WINNER = 'Blue' THEN 1 END) AS Blue,
COUNT(CASE WHEN WINNER = 'Red' THEN 1 END) AS Red,
COUNT(CASE WHEN WINNER = 'Draw' THEN 1 END) AS Draw
FROM [dbo].[123]
GROUP BY YEAR(DATE)
) SELECT
*,
CAST(((Blue * 1.00) / ((Blue * 1.00)+(Red*1.00)+(Draw * 1.00))*100) AS numeric(10,2)) AS 'Blue win %',
CAST(((Red * 1.00) / ((Blue * 1.00)+(Red*1.00)+(Draw * 1.00))*100) AS numeric(10,2)) AS 'Red win %',
CAST(((Draw * 1.00) / ((Blue * 1.00)+(Red*1.00)+(Draw * 1.00))*100) AS numeric(10,2)) AS 'Draw %'
FROM C
WHERE [year] >= 2010
ORDER by [year] DESC

-- Now, let's find out who has the longest winning streak in the UFC.
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
SUM(CASE WHEN winner <> R_fighter THEN 1 END)   -- starts with null, ADD +1 when Fighter loses - streak bronken.
OVER (PARTITION by R_FIGHTER ORDER BY [date] ) TMP
FROM L) 
SELECT
R_FIGHTER,
COUNT(*) AS STREAK
FROM M
WHERE R_fighter = WINNER                           -- List of consecutive win streaks of each fighter.
group BY R_fighter, TMP                         
ORDER BY STREAK DESC
-- It's Anderson Silva! Even though lately he's having some rough time, being undefeated for 16 consecutive fights is something clearly out of this world.

-- Most wins by decision.
WITH D AS (
SELECT
R_fighter as Fighter,
max(R_win_by_Decision_Split + R_win_by_Decision_Majority + R_win_by_Decision_Unanimous) AS [Wins by decision]
FROM [dbo].[123]
GROUP BY R_fighter
UNION
SELECT
B_fighter as Fighter,
max(b_win_by_Decision_Split + B_win_by_Decision_Majority + B_win_by_Decision_Unanimous) AS [Wins by decision]
FROM [dbo].[123]
group by B_fighter)
select * from D
ORDER BY [Wins by decision] DESC

-- Most wins by decision.
WITH D AS (
SELECT
R_fighter as Fighter,
max(R_win_by_Decision_Split + R_win_by_Decision_Majority + R_win_by_Decision_Unanimous) AS [Wins by decision],
R_win_by_Decision_Majority AS [Wins by majority decision],
R_win_by_Decision_Unanimous AS [Wins by unanimous decision],
R_win_by_Decision_Split AS [Wins by split decision]
FROM [dbo].[123]
GROUP BY R_fighter, R_win_by_Decision_Majority, R_win_by_Decision_Unanimous, R_win_by_Decision_Split
UNION
SELECT
B_fighter as Fighter,
max(b_win_by_Decision_Split + B_win_by_Decision_Majority + B_win_by_Decision_Unanimous) AS [Wins by decision],
b_win_by_Decision_Majority AS [Wins by majority decision],
b_win_by_Decision_Unanimous AS [Wins by unanimous decision],
b_win_by_Decision_Split AS [Wins by split decision]
FROM [dbo].[123]
group by B_fighter, b_win_by_Decision_Majority, B_win_by_Decision_Unanimous, b_win_by_Decision_Split)
select TOP 10 WITH TIES 
* from D
ORDER BY [Wins by decision] DESC, [Wins by majority decision] DESC, [Wins by unanimous decision] DESC, [Wins by split decision] DESC

-- Most wins by KO/TKO.
WITH KO AS (
SELECT
R_fighter AS Fighter,
max(R_win_by_KO_TKO + R_win_by_TKO_Doctor_Stoppage) AS [Total wins by KO/TKO],
R_win_by_KO_TKO AS [Wins by KO/TKO],
R_win_by_TKO_Doctor_Stoppage AS [Wins by doctor stoppage]
FROM [dbo].[123]
GROUP BY R_fighter, R_win_by_KO_TKO, R_win_by_TKO_Doctor_Stoppage
UNION
SELECT
B_fighter AS Fighter,
max(B_win_by_KO_TKO + B_win_by_TKO_Doctor_Stoppage) AS [Total wins by KO/TKO],
B_win_by_KO_TKO AS [Wins by KO/TKO],
B_win_by_TKO_Doctor_Stoppage AS [Wins by doctor stoppage]
FROM [dbo].[123]
GROUP BY B_fighter, B_win_by_KO_TKO, B_win_by_TKO_Doctor_Stoppage)
SELECT TOP 10 WITH TIES
* FROM KO
ORDER BY [Total wins by KO/TKO] DESC

-- Most wins by Submission.
WITH S AS (
SELECT
R_fighter AS Fighter,
max(R_win_by_Submission) AS [Total wins by Submission]
FROM [dbo].[123]
GROUP BY R_fighter, R_win_by_Submission
UNION
SELECT
B_fighter AS Fighter,
max(B_win_by_Submission) AS [Total wins by Submission]
FROM [dbo].[123]
GROUP BY B_fighter, B_win_by_Submission)
SELECT TOP 10 WITH TIES
Fighter,
MAX([Total wins by Submission]) AS [Wins by submission]
FROM S
GROUP BY Fighter
order by MAX([Total wins by Submission]) DESC

-- Lets take a look on best grapplers average stats in fights won by submission.
WITH sub AS(
SELECT
R_fighter AS Fighter,
R_win_by_Submission AS [Total wins by Submission],
ISNULL(R_avg_SUB_ATT,0) AS [Submission attempts],
ISNULL(R_avg_TD_ATT, 0) AS [Takedowns attempts],
ISNULL(R_avg_TD_landed, 0) AS [Takedowns landed],
ISNULL(R_avg_GROUND_att,0) as [Ground attacks],
ISNULL(R_avg_GROUND_landed,0) as [Ground attacks landed],
ISNULL(R_avg_CTRL_time_seconds,0) [Ground control time]
FROM [dbo].[123]
WHERE R_fighter IN (SELECT fighter from vwSub) 
UNION
SELECT
B_fighter AS Fighter,
B_win_by_Submission AS [Total wins by Submission],
ISNULL(B_avg_SUB_ATT,0) AS [Submission attempts],
ISNULL(B_avg_TD_ATT, 0) AS [Takedowns attempts],
ISNULL(B_avg_TD_landed, 0) AS [Takedowns landed],
ISNULL(B_avg_GROUND_att,0) as [Ground attacks],
ISNULL(B_avg_GROUND_landed,0) as [Ground attacks landed],
ISNULL(B_avg_CTRL_time_seconds,0) [Ground control time]
FROM [dbo].[123]
WHERE B_fighter IN (SELECT fighter from vwSub)
) SELECT DISTINCT 
FIGHTER,
MAX([Total wins by Submission]) [Total wins by Submission],
CAST(AVG([Takedowns attempts]) AS numeric(4,2)) [Takedowns attempts],
CAST(AVG([Takedowns landed]) AS numeric(4,2)) [Takedowns landed],
CAST(AVG([Submission attempts]) AS numeric(4,2)) [Submission attempts],
CAST(AVG([Ground attacks]) AS numeric(4,2)) [Ground attacks],
CAST(AVG([Ground attacks landed]) AS numeric(4,2)) [Ground attacks landed],
CAST(AVG([Ground control time]) AS numeric(5,2)) [Ground control time]
FROM SUB
GROUP BY Fighter
ORDER BY [Total wins by Submission] DESC, Fighter;

-- Let's look closer at each weightclass
SELECT
weight_class,
COUNT(*) [No. of fights]
FROM [dbo].[123]
GROUP BY weight_class
ORDER BY [No. of fights] desc
-- It appears that welterweight and lightweight is the most popular. Note that fighter during their career can fight in multiple categories.

-- Basic data of average fighter in each class. 
SELECT
weight_class,
CAST(AVG(R_age + B_age) / 2 AS numeric(4,2)) AS Age,
CAST(AVG(R_Height_cms + B_Weight_lbs) / 2 AS numeric (5,2)) AS Height,
CAST(AVG((R_Weight_lbs / 2.205) + (B_Weight_lbs / 2.205)) / 2.0 AS numeric(5,2)) AS Weight
FROM [dbo].[123]
GROUP BY weight_class
ORDER BY Weight desc

-- Top 5 venues that have hosted the most number of UFC events
SELECT TOP 5
[location],
COUNT(*) AS [Number of Events]
FROM [dbo].[123]
GROUP BY [location]
ORDER BY [Number of Events] DESC

-- Top 5 venues that have hosted the most number of UFC events outside of the USA
SELECT TOP 5
[location],
COUNT(*) AS [Number of Events]
FROM [dbo].[123]
WHERE RIGHT([location],3) <> 'USA'
GROUP BY [location]
ORDER BY [Number of Events] DESC

-- Top 5 venues that have hosted the most number title bout fights
SELECT TOP 15
[location],
COUNT(*) AS [Number of title bout fights]
FROM [dbo].[123]
WHERE title_bout = 1
GROUP BY [location]
ORDER BY [Number of title bout fights] DESC

-- Top 5 luckiest venues for title challengers
SELECT TOP 5
[location],
COUNT(*) AS [Number of Events]
FROM [dbo].[123]
WHERE title_bout = 1 and winner = 'Blue' 
GROUP BY [location]
ORDER BY [Number of Events] DESC

-- Fighters stance popularity
WITH S AS (
SELECT
B_Stance AS stance
FROM [dbo].[123]
UNION ALL
SELECT
R_Stance
FROM [dbo].[123])
SELECT 
stance,
count(*) AS Popularity,
CAST((COUNT(*) *1.00 / (SELECT COUNT(*) FROM S WHERE STANCE IS NOT NULL) * 1.00)*100 AS NUMERIC(5,2)) as [Popularity %]
FROM S 
WHERE STANCE IS NOT NULL
GROUP BY stance
ORDER BY Popularity DESC

-- Oldboys vs Youngsters, fights with biggest age gaps.
WITH AGE_DIFF AS (
SELECT
R_fighter,
B_fighter,
CASE WHEN Winner = 'Blue' THEN R_fighter ELSE B_fighter END AS [Winner],
location,
Referee,
date,
B_age - R_age AS [Age difference],
weight_class,
RANK() OVER(ORDER BY R_age - B_age) rnk
FROM [dbo].[123]
WHERE R_age IS NOT NULL AND B_age IS NOT NULl)
SELECT
R_fighter,
B_fighter,
Winner,
Location,
Referee,
Date,
[Age difference],
weight_class AS [Weight class]
FROM AGE_DIFF
WHERE rnk <= 3
