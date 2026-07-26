-- Appendix: SQL Queries
-- 1. Subscription Funnel (with trial-and-payment overlap, by country)
SELECT
    stages.country,
    COUNT(DISTINCT stages.user_id) AS t_signed,
    SUM(trial) AS t_trial,
    SUM(first_payment) AS t_first_payment,
    SUM(renewal) AS t_renewal,
    SUM(upgrade) AS t_upgrade,
    SUM(CASE WHEN trial = 1 AND first_payment = 1 THEN 1 ELSE 0 END) AS t_trial_and_payment
FROM (
    SELECT
        u.country,
        u.user_id,
        MAX(CASE WHEN transaction_type = 'trial_start' THEN 1 ELSE 0 END) AS trial,
        MAX(CASE WHEN transaction_type = 'first_payment' THEN 1 ELSE 0 END) AS first_payment,
        MAX(CASE WHEN transaction_type = 'renewal' THEN 1 ELSE 0 END) AS renewal,
        MAX(CASE WHEN transaction_type = 'upgrade' THEN 1 ELSE 0 END) AS upgrade
    FROM users u
    LEFT JOIN transactions t ON u.user_id = t.user_id
    GROUP BY user_id
) AS stages
GROUP BY stages.country;


-- 2. Monthly Recurring Revenue (MRR)
SELECT
    DATE_FORMAT(date, '%Y-%m') AS date,
    SUM(CASE WHEN plan_id != 'P05' THEN amount_usd ELSE 0 END) AS recurring_revenue,
    SUM(CASE WHEN plan_id = 'P05' THEN amount_usd ELSE 0 END) AS lifetime_plan_revenue
FROM transactions t
GROUP BY DATE_FORMAT(date, '%Y-%m');


-- 3. Cohort source data (for retention analysis)
SELECT
    u.user_id,
    u.signup_date,
    t.transaction_type,
    DATE_FORMAT(t.date, '%Y-%m-%d') AS transaction_date,
    sp.plan_name,
    sp.duration_days
FROM users u
JOIN transactions t ON u.user_id = t.user_id
JOIN subscription_plans sp ON t.plan_id = sp.plan_id
WHERE t.transaction_type IN ('first_payment', 'renewal', 'upgrade');


-- 4. Trial-to-Paid Conversion by Country
SELECT
    SUM(trial) AS t_trial,
    SUM(CASE WHEN trial = 1 AND first_payment = 1 THEN 1 ELSE 0 END) AS t_trial_and_payment,
    stages.country
FROM (
    SELECT
        u.country,
        u.user_id,
        MAX(CASE WHEN transaction_type = 'trial_start' THEN 1 ELSE 0 END) AS trial,
        MAX(CASE WHEN transaction_type = 'first_payment' THEN 1 ELSE 0 END) AS first_payment
    FROM users u
    LEFT JOIN transactions t ON u.user_id = t.user_id
    GROUP BY user_id
) AS stages
GROUP BY stages.country;


-- 5. Trial-to-Paid Conversion by Acquisition Channel
SELECT
    SUM(trial) AS t_trial,
    SUM(CASE WHEN trial = 1 AND first_payment = 1 THEN 1 ELSE 0 END) AS t_trial_and_payment,
    stages.acquisition_channel
FROM (
    SELECT
        u.user_id,
        u.acquisition_channel,
        MAX(CASE WHEN transaction_type = 'trial_start' THEN 1 ELSE 0 END) AS trial,
        MAX(CASE WHEN transaction_type = 'first_payment' THEN 1 ELSE 0 END) AS first_payment
    FROM users u
    LEFT JOIN transactions t ON u.user_id = t.user_id
    GROUP BY user_id
) AS stages
GROUP BY stages.acquisition_channel;

