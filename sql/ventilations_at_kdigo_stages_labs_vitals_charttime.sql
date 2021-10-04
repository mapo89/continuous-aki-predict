-- Determines if a patient is ventilated for each chart time in kdigo_stages, labs, and vitals.
-- Creates a table with the result.
-- Requires the `ventdurations` and `kdigo_stages` table

DROP MATERIALIZED VIEW IF EXISTS mimiciii.vent_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciii.vent_kdigo_stages_labs_vitals_charttime AS
select *
from (
(
-- Ventilation for each time in kdigo_stages
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid ventilation event
  -- in this case, we say they are ventilated
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vent
from mimiciii.kdigo_stages ie
left join mimiciii.ventdurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- ventilation duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Ventilation for each time in labs
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid ventilation event
  -- in this case, we say they are ventilated
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vent
from mimiciii.labs ie
left join mimiciii.ventdurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- ventilation duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
) union (
-- Ventilation for each time in vitals
select
  ie.icustay_id, charttime
  -- if vd.icustay_id is not null, then they have a valid ventilation event
  -- in this case, we say they are ventilated
  -- otherwise, they are not
  , max(case
      when vd.icustay_id is not null then 1
    else 0 end) as vent
from mimiciii.vitals ie
left join mimiciii.ventdurations vd
  on ie.icustay_id = vd.icustay_id
  and
  (
    -- ventilation duration overlaps with charttime
    (vd.starttime <= ie.charttime and vd.endtime >= ie.charttime)
  )
group by ie.icustay_id, charttime
)
) u
order by icustay_id, charttime;