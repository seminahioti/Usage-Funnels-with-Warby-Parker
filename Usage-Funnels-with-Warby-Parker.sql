-- Step 1: To help users find their perfect frame, Warby Parker has a Style Quiz that has the following questions: “What are you looking for?”, “What’s your fit?”, “Which shapes do you like?”, “Which colors do you like?”, “When was your last eye exam?”. The users’ responses are stored in a table called survey. Select all columns from the first 10 rows. What columns does the table have?
SELECT *
FROM survey
LIMIT 10;

-- Step 2: Users will “give up” at different points in the survey. Let’s analyze how many users move from Question 1 to Question 2, etc. Create a quiz funnel using the GROUP BY command. What is the number of responses for each question? (comment: we want to find out how far people get in this survey before they quit.)
SELECT question, -- we want to get a count of how many people answer each question, we'll get two columns, one for the question and one for the total count
  COUNT(DISTINCT user_id) AS 'Number of Responses' -- giving a name to the column
FROM survey
GROUP BY question;

-- Step 3: Using a spreadsheet program like Excel or Google Sheets, calculate the percentage of users who answer each question: Which question(s) of the quiz have a lower completion rates? What do you think is the reason? we will use googlesheets for this task.

-- Step 4: Warby Parker’s purchase funnel is: Take the Style Quiz → Home Try-On → Purchase the Perfect Pair of Glasses. During the Home Try-On stage, we will be conducting an A/B Test: 50% of the users will get 3 pairs to try on, 50% of the users will get 5 pairs to try on. Let’s find out whether or not users who get more pairs to try on at home will be more likely to make a purchase. The data will be distributed across three tables: quiz, home_try_on, purchase. Examine the first five rows of each table. What are the column names?
SELECT *
FROM quiz
LIMIT 5;

SELECT *
FROM home_try_on
LIMIT 5;

SELECT *
FROM purchase
LIMIT 5;

-- Step 5: We’d like to create a new table. Each row will represent a single user from the browse table. If the user has any entries in home_try_on, then is_home_try_on will be True. Νumber_of_pairs comes from home_try_on table. If the user has any entries in purchase, then is_purchase will be True. Use a LEFT JOIN to combine the three tables, starting with the top of the funnel (quiz) and ending with the bottom of the funnel (purchase). Select only the first 10 rows from this table (otherwise, the query will run really slowly!)
SELECT DISTINCT q.user_id, 
  h.user_id IS NOT NULL AS 'is_home_try_on',
  h.number_of_pairs,
  p.user_id IS NOT NULL AS 'is_purchase'
  FROM quiz q
  LEFT JOIN home_try_on h
    ON q.user_id = h.user_id
  LEFT JOIN purchase p
    ON p.user_id = q.user_id
  LIMIT 10; 

-- Step 6: Once we have the data in this format, we can analyze it in several ways: We can calculate overall conversion rates by aggregating across all rows. We can compare conversion from quiz→home_try_on and home_try_on→purchase. We can calculate the difference in purchase rates between customers who had 3 number_of_pairs with ones who had 5.And more! We can also use the original tables to calculate things like: The most common results of the style quiz. The most common types of purchase made. And more! What are some actionable insights for Warby Parker?
WITH 
q AS (
  SELECT '1-quiz' AS stage, COUNT(DISTINCT user_id) 
    FROM quiz -- how many people reached the first stage of the funnel
),
h AS (
  SELECT '2-home-try-on' AS stage, 
  COUNT(DISTINCT user_id)
  FROM home_try_on -- how many reached the second stage of trying 
), 
p AS (
  SELECT '3-purchase' AS stage,
COUNT(DISTINCT user_id)
  FROM purchase -- third stage of the funnel, people who actually purchased a pair of glasses (unique users)
)
SELECT * 
FROM q
UNION ALL SELECT *
FROM h
UNION ALL SELECT *
FROM p;

-- Now we need a column of AB_variant, a column of home_trial and a column of purchase. This query is taking a look at users in the second stage of the funnel. Those who recieved other three pair of glasses or five pairs. We list the total a mount of people who recieved these pairs and then we list the amount of purchases and we list the amount of people who eventually made a purchase. 

WITH base_table AS(
  SELECT DISTINCT q.user_id,
    h.user_id IS NOT NULL AS 'is_home_try_on', 
    h.number_of_pairs AS 'AB_variant', 
    p.user_id IS NOT NULL AS 'is_purchase'
  FROM quiz q
  LEFT JOIN home_try_on h
    ON q.user_id = h.user_id
  LEFT JOIN purchase p
    ON p.user_id = q.user_id
)
SELECT AB_variant,
  SUM(CASE WHEN is_home_try_on =1 
    THEN 1
    ELSE 0
    END) 'home_trial', 
  SUM(CASE WHEN is_purchase = 1
    THEN 1
    ELSE 0
    END) 'purchase'
FROM base_table
GROUP BY AB_variant
HAVING home_trial > 0;
