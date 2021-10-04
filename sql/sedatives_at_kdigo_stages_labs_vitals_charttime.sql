-- Determines if a patient is subject to sedatives for each chart time in kdigo_stages.
-- Creates a table with the result.
-- Requires the `kdigo_stages` and `sedativesduration`, `labs`, `vitals` table

DROP MATERIALIZED VIEW IF EXISTS mimiciii.sedatives_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciii.sedatives_kdigo_stages_labs_vitals_charttime AS
select *
from (
(
-- Sedatives for each time in kdigo_stages
select
  ie.icustay_id, charttime
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as sedative
from mimiciii.kdigo_stages ie
left join mimiciii.sedativedurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Sedatives for each time in labs
select
  ie.icustay_id, charttime
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as sedative
from mimiciii.labs ie
left join mimiciii.sedativedurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Sedatives for each time in vitals
select
  ie.icustay_id, charttime
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as sedative
from mimiciii.vitals ie
left join mimiciii.sedativedurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
)
) u
order by icustay_id, charttime;