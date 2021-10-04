-- Determines if a patient is ventilated for each chart time in kdigo_stages.
-- Creates a table with the result.
-- Requires the `vasopressordurations` and `kdigo_stages`, `labs` and `vitals` table

DROP MATERIALIZED VIEW IF EXISTS mimiciii.vasopressor_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciii.vasopressor_kdigo_stages_labs_vitals_charttime AS
select *
from (
(
-- Vasopressors for each time in kdigo_stages
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid vasopressor event
  -- in this case, we say they are given vasopressor
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vasopressor
from mimiciii.kdigo_stages ie
left join mimiciii.vasopressordurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- vasopressor duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Vasopressors for each time in labs
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid vasopressor event
  -- in this case, we say they are given vasopressor
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vasopressor
from mimiciii.labs ie
left join mimiciii.vasopressordurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- vasopressor duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Vasopressors for each time in vitals
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid vasopressor event
  -- in this case, we say they are given vasopressor
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vasopressor
from mimiciii.vitals ie
left join mimiciii.vasopressordurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- vasopressor duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
)
) u
order by icustay_id, charttime;