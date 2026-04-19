-- =============================================================
-- Task 1: Per-country stats
-- =============================================================
WITH deposits AS (
    SELECT
        user_id,
        SUM(amount) AS total_deposits
    FROM transactions
    WHERE type = 'deposit'
    GROUP BY user_id
)
SELECT
    u.country,
    COUNT(*)                                                  AS total_users,
    COUNT(d.user_id)                                          AS paying_users,
    COALESCE(SUM(d.total_deposits), 0)                        AS sum_deposits,
    ROUND(
        COUNT(d.user_id)::NUMERIC / NULLIF(COUNT(*), 0),
        4
    )                                                         AS paying_share
FROM users u
LEFT JOIN deposits d ON d.user_id = u.user_id
GROUP BY u.country
ORDER BY sum_deposits DESC;

-- =============================================================
-- Task 2: D1 Retention
-- =============================================================
WITH d1_activity AS (
    SELECT DISTINCT
        u.user_id
    FROM users u
    INNER JOIN transactions t
        ON t.user_id = u.user_id
       AND t.transaction_date = u.registration_date + 1
)
SELECT
    COUNT(*)                                                  AS total_users,
    COUNT(d1.user_id)                                         AS retained_d1,
    ROUND(
        COUNT(d1.user_id)::NUMERIC / NULLIF(COUNT(*), 0),
        4
    )                                                         AS retention_d1
FROM users u
LEFT JOIN d1_activity d1 ON d1.user_id = u.user_id;

-- =============================================================
-- Task 3: ARPU and ARPPU
-- =============================================================
WITH agg AS (
    SELECT
        SUM(CASE WHEN type = 'deposit' THEN amount ELSE 0 END) AS total_deposits,
        COUNT(DISTINCT user_id) AS active_users,
        COUNT(DISTINCT CASE WHEN type = 'deposit' THEN user_id END) AS paying_users
    FROM transactions
)
SELECT
    ROUND(total_deposits / NULLIF(active_users, 0), 4) AS arpu, -- in task ARPU = revenue / users with transactions, but in most domains ARPU:revenue / all users
    ROUND(total_deposits / NULLIF(paying_users, 0), 4) AS arppu
FROM agg;

-- =============================================================
-- Task 4: Top depositor per country
-- =============================================================
WITH user_deposits AS (
    SELECT
        u.user_id,
        u.country,
        SUM(t.amount) AS total_deposits
    FROM users u
    INNER JOIN transactions t
        ON  t.user_id = u.user_id
        AND t.type    = 'deposit'
    GROUP BY u.user_id, u.country
),
ranked AS (
    SELECT
        user_id,
        country,
        total_deposits,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_deposits DESC) AS rn
    FROM user_deposits
)
SELECT
    country,
    user_id,
    total_deposits
FROM ranked
WHERE rn = 1
ORDER BY country;