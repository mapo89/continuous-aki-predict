-- This query extracts durations of sedative administration

-- Consecutive administrations are numbered 1, 2, ...
-- Total time on the drug can be calculated from this table
-- by grouping using ICUSTAY_ID

-- select only the ITEMIDs from the inputevents_cv table related to sedative
DROP MATERIALIZED VIEW IF EXISTS mimiciii.SEDATIVEDURATIONS;
CREATE MATERIALIZED VIEW mimiciii.SEDATIVEDURATIONS as
with io_cv as
(
  select
    icustay_id, charttime, itemid, stopped
    -- ITEMIDs (42273, 42802) accidentally store rate in amount column
    , case
        when itemid in (42273, 42802)
          then amount
        else rate
      end as rate
    , case
        when itemid in (42273, 42802)
          then rate
        else amount
      end as amount
  from inputevents_cv
  where itemid in
  (
    30124,30150,30308,30118,30149,30131
  )
)
-- select only the ITEMIDs from the inputevents_mv table related to sedative
, io_mv as
(
  select
    icustay_id, linkorderid, starttime, endtime
  from inputevents_mv io
  -- Subselect the sedative ITEMIDs
  where itemid in
  (
  221668,221744,225972,225942,222168
  )
  and statusdescription != 'Rewritten' -- only valid orders
)
, sedativecv1 as
(
  select
    icustay_id, charttime, itemid
    -- case statement determining whether the ITEMID is an instance of sedative usage
    , 1 as sedative

    -- the 'stopped' column indicates if a sedative has been disconnected
    , max(case when stopped in ('Stopped','D/C''d') then 1
          else 0 end) as sedative_stopped

    , max(case when rate is not null then 1 else 0 end) as sedative_null
    , max(rate) as sedative_rate
    , max(amount) as sedative_amount

  from io_cv
  group by icustay_id, charttime, itemid
)
, sedativecv2 as
(
  select v.*
    , sum(sedative_null) over (partition by icustay_id, itemid order by charttime) as sedative_partition
  from
    sedativecv1 v
)
, sedativecv3 as
(
  select v.*
    , first_value(sedative_rate) over (partition by icustay_id, itemid, sedative_partition order by charttime) as sedative_prevrate_ifnull
  from
    sedativecv2 v
)
, sedativecv4 as
(
select
    icustay_id
    , charttime
    , itemid
    -- , (CHARTTIME - (LAG(CHARTTIME, 1) OVER (partition by icustay_id, vaso order by charttime))) AS delta

    , sedative
    , sedative_rate
    , sedative_amount
    , sedative_stopped
    , sedative_prevrate_ifnull

    -- We define start time here
    , case
        when sedative = 0 then null

        -- if this is the first instance of the sedative drug
        when sedative_rate > 0 and
          LAG(sedative_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, itemid, sedative, sedative_null
          order by charttime
          )
          is null
          then 1

        -- you often get a string of 0s
        -- we decide not to set these as 1, just because it makes sedativenum sequential
        when sedative_rate = 0 and
          LAG(sedative_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, itemid, sedative
          order by charttime
          )
          = 0
          then 0

        -- sometimes you get a string of NULL, associated with 0 volumes
        -- same reason as before, we decide not to set these as 1
        -- sedative_prevrate_ifnull is equal to the previous value *iff* the current value is null
        when sedative_prevrate_ifnull = 0 and
          LAG(sedative_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, itemid, sedative
          order by charttime
          )
          = 0
          then 0

        -- If the last recorded rate was 0, newsedative = 1
        when LAG(sedative_prevrate_ifnull,1)
          OVER
          (
          partition by icustay_id, itemid, sedative
          order by charttime
          ) = 0
          then 1

        -- If the last recorded sedative was D/C'd, newsedative = 1
        when
          LAG(sedative_stopped,1)
          OVER
          (
          partition by icustay_id, itemid, sedative
          order by charttime
          )
          = 1 then 1

        -- ** not sure if the below is needed
        --when (CHARTTIME - (LAG(CHARTTIME, 1) OVER (partition by icustay_id, vaso order by charttime))) > (interval '4 hours') then 1
      else null
      end as sedative_start

FROM
  sedativecv3
)
-- propagate start/stop flags forward in time
, sedativecv5 as
(
  select v.*
    , SUM(sedative_start) OVER (partition by icustay_id, itemid, sedative order by charttime) as sedative_first
FROM
  sedativecv4 v
)
, sedativecv6 as
(
  select v.*
    -- We define end time here
    , case
        when sedative = 0
          then null

        -- If the recorded sedative was D/C'd, this is an end time
        when sedative_stopped = 1
          then sedative_first

        -- If the rate is zero, this is the end time
        when sedative_rate = 0
          then sedative_first

        -- the last row in the table is always a potential end time
        -- this captures patients who die/are discharged while on sedatives
        -- in principle, this could add an extra end time for the sedative
        -- however, since we later group on sedative_start, any extra end times are ignored
        when LEAD(CHARTTIME,1)
          OVER
          (
          partition by icustay_id, itemid, sedative
          order by charttime
          ) is null
          then sedative_first

        else null
        end as sedative_stop
    from sedativecv5 v
)

-- -- if you want to look at the results of the table before grouping:
-- select
--   icustay_id, charttime, vaso, vaso_rate, vaso_amount
--     , case when vaso_stopped = 1 then 'Y' else '' end as stopped
--     , vaso_start
--     , vaso_first
--     , vaso_stop
-- from vasocv6 order by charttime;


, sedativecv as
(
-- below groups together sedative administrations into groups
select
  icustay_id
  , itemid
  -- the first non-null rate is considered the starttime
  , min(case when sedative_rate is not null then charttime else null end) as starttime
  -- the *first* time the first/last flags agree is the stop time for this duration
  , min(case when sedative_first = sedative_stop then charttime else null end) as endtime
from sedativecv6
where
  sedative_first is not null -- bogus data
and
  sedative_first != 0 -- sometimes *only* a rate of 0 appears, i.e. the drug is never actually delivered
and
  icustay_id is not null -- there are data for "floating" admissions, we don't worry about these
group by icustay_id, itemid, sedative_first
having -- ensure start time is not the same as end time
 min(charttime) != min(case when sedative_first = sedative_stop then charttime else null end)
and
  max(sedative_rate) > 0 -- if the rate was always 0 or null, we consider it not a real drug delivery
)
-- we do not group by ITEMID in below query
-- this is because we want to collapse all sedative together
, sedativecv_grp as
(
SELECT
  s1.icustay_id,
  s1.starttime,
  MIN(t1.endtime) AS endtime
FROM sedativecv s1
INNER JOIN sedativecv t1
  ON  s1.icustay_id = t1.icustay_id
  AND s1.starttime <= t1.endtime
  AND NOT EXISTS(SELECT * FROM sedativecv t2
                 WHERE t1.icustay_id = t2.icustay_id
                 AND t1.endtime >= t2.starttime
                 AND t1.endtime < t2.endtime)
WHERE NOT EXISTS(SELECT * FROM sedativecv s2
                 WHERE s1.icustay_id = s2.icustay_id
                 AND s1.starttime > s2.starttime
                 AND s1.starttime <= s2.endtime)
GROUP BY s1.icustay_id, s1.starttime
ORDER BY s1.icustay_id, s1.starttime
)
-- now we extract the associated data for metavision patients
-- do not need to group by itemid because we group by linkorderid
, sedativemv as
(
  select
    icustay_id, linkorderid
    , min(starttime) as starttime, max(endtime) as endtime
  from io_mv
  group by icustay_id, linkorderid
)
, sedativemv_grp as
(
SELECT
  s1.icustay_id,
  s1.starttime,
  MIN(t1.endtime) AS endtime
FROM sedativemv s1
INNER JOIN sedativemv t1
  ON  s1.icustay_id = t1.icustay_id
  AND s1.starttime <= t1.endtime
  AND NOT EXISTS(SELECT * FROM sedativemv t2
                 WHERE t1.icustay_id = t2.icustay_id
                 AND t1.endtime >= t2.starttime
                 AND t1.endtime < t2.endtime)
WHERE NOT EXISTS(SELECT * FROM sedativemv s2
                 WHERE s1.icustay_id = s2.icustay_id
                 AND s1.starttime > s2.starttime
                 AND s1.starttime <= s2.endtime)
GROUP BY s1.icustay_id, s1.starttime
ORDER BY s1.icustay_id, s1.starttime
)
select
  icustay_id
  -- generate a sequential integer for convenience
  , ROW_NUMBER() over (partition by icustay_id order by starttime) as sedativenum
  , starttime, endtime
  , extract(epoch from endtime - starttime)/60/60 AS duration_hours
  -- add durations
from
  sedativecv_grp

UNION

select
  icustay_id
  , ROW_NUMBER() over (partition by icustay_id order by starttime) as sedativenum
  , starttime, endtime
  , extract(epoch from endtime - starttime)/60/60 AS duration_hours
  -- add durations
from
  sedativemv_grp

order by icustay_id, sedativenum;