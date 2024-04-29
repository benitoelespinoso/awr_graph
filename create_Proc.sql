
CREATE OR REPLACE PROCEDURE PERFSTAT.proc_report_diario(C_FECHA date)

is

-- (C_FECHA_INICIO date,C_FECHA_INI_MES date,C_FECHA_FIN date) AS

-- C_MES           DATE := C_FECHA_INI_MES;
-- C_INICIO        DATE := C_FECHA_INICIO;
-- C_FIN           DATE := C_FECHA_FIN;


v_dbtim number;



v_ini varchar2(24);
v_fin varchar2(24);
v_db varchar2(24);
v_instnum varchar2(24);



BEGIN


/* DELETE de la info a instertar (RESET de anteriores) */



delete from perfstat.t_time_mod
where trunc(fecha) = trunc(c_fecha);

delete from perfstat.top_n_wait
where trunc(fecha) = trunc(c_fecha);


commit;


 select  SNAP_ID
 into v_ini
 from STATS$SNAPSHOT
 where trunc(snap_time)=trunc(C_FECHA)
 and to_number(TO_CHAR(snap_time, 'HH24')) = 9;

 select
 SNAP_ID
 into v_fin
 from STATS$SNAPSHOT
 where trunc(snap_time)=trunc(C_FECHA)
 and
 to_number(TO_CHAR(snap_time, 'HH24')) = 15;



 select
 distinct(dbid) into v_db
 from
 STATS$SNAPSHOT;

 select
 distinct(instance_number) into v_instnum
 from
 STATS$SNAPSHOT;



-- la query que depende de los valores recogidos por el cursor. Que realmente es
-- un INTO VAR
-- pues siempre vuelve un solo dato

 select (e.value - b.value)                   into v_dbtim
  from stats$sys_time_model e
     , stats$sys_time_model b
     , stats$time_model_statname sn
         where b.snap_id                = v_ini
           and e.snap_id                = v_fin
           and b.dbid                   = v_db
           and e.dbid                   = v_db
           and b.instance_number        = v_instnum
           and e.instance_number        = v_instnum
   and sn.stat_name             = 'DB time'
   and b.stat_id                = e.stat_id
   and e.stat_id                = sn.stat_id;



-- y con esto ya:


 insert into perfstat.t_time_mod (
 select trunc(C_FECHA), statnam
      , tdif/1000000                        tdifs
      , decode(order_col, 0, 100*tdif/v_dbtim , to_number(null) ) pctdb
      , order_col
   from (select sn.stat_name               statnam
              , (e.value - b.value)        tdif
              , decode( sn.stat_name
                      , 'DB time',                 1
                      , 'background cpu time',     2
                      , 'background elapsed time', 2
                      , 0
                      )                    order_col
           from stats$sys_time_model e
              , stats$sys_time_model b
              , stats$time_model_statname sn
          where b.snap_id                = v_ini
            and e.snap_id                = v_fin
            and b.dbid                   = v_db
            and e.dbid                   = v_db
            and b.instance_number        = v_instnum
            and e.instance_number        = v_instnum
            and b.stat_id                = e.stat_id
            and sn.stat_id               = e.stat_id
            and e.value - b.value        > 0
        ));

 commit;


insert into perfstat.top_n_wait (
select trunc(C_FECHA),
e.event   event
                     , e.total_waits - nvl(b.total_waits,0)  waits
                     , (e.time_waited_micro - nvl(b.time_waited_micro,0))/1000000  time
                     , decode ( (e.total_waits - nvl(b.total_waits, 0)), 0, to_number(NULL)
                             ,    ( (e.time_waited_micro - nvl(b.time_waited_micro,0)) / 1000 )
                                / (e.total_waits - nvl(b.total_waits,0))
                             )        avwait
                 from stats$system_event b
                    , stats$system_event e
                where b.snap_id(+)          = v_ini
            and e.snap_id                = v_fin
            and b.dbid                   = v_db
            and e.dbid                   = v_db
            and b.instance_number        = v_instnum
            and e.instance_number        = v_instnum
                  and b.event(+)            = e.event
                  and e.total_waits         > nvl(b.total_waits,0)
                  and e.event not in (select event from stats$idle_event)
);

commit;




end;
/


CREATE OR REPLACE PROCEDURE PERFSTAT.proc_report_porhora

is

-- (C_FECHA_INICIO date,C_FECHA_INI_MES date,C_FECHA_FIN date) AS

-- C_MES           DATE := C_FECHA_INI_MES;
-- C_INICIO        DATE := C_FECHA_INICIO;
-- C_FIN           DATE := C_FECHA_FIN;


v_dbtim number;



v_ini varchar2(24);
v_fin varchar2(24);
v_db varchar2(24);
v_instnum varchar2(24);


/* resueltas de meses anteriores */

BEGIN

/*

 select
 SNAP_ID
 into v_ini
 from STATS$SNAPSHOT
 where trunc(snap_time)=trunc(sysdate)
 and
 to_number(TO_CHAR(snap_time, 'HH24')) = 9;

 select
 SNAP_ID
 into v_fin
 from STATS$SNAPSHOT
 where trunc(snap_time)=trunc(sysdate)
 and
 to_number(TO_CHAR(snap_time, 'HH24')) = 15;



 select
 distinct(dbid) into v_db
 from
 STATS$SNAPSHOT;

 select
 distinct(instance_number) into v_instnum
 from
 STATS$SNAPSHOT;

*/

-- la query que depende de los valores recogidos por el cursor. Que realmente es
-- un INTO VAR
-- pues siempre vuelve un solo dato

insert into perfstat.T_CPU
SELECT
   TO_CHAR(ash.sample_time, 'dd-mm-yyyy hh24:mi') sample_time,
   (ROUND((ash.sample_time - TO_DATE('19700101','yyyymmdd')) * 86400 - TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*3600)) hora,
   round(ash.fcpu + ash.bcpu,2) total_cpu,
   round(ash.fcpu,2)  f_cpu,
   round(ash.bcpu,2)  b_cpu,
   (SELECT MAX(value) FROM SYS.V_$osstat WHERE stat_name = 'NUM_CPUS') CPU_maquina
 FROM
   (SELECT
      TRUNC(sample_time,'MI')                              sample_time,
      to_number((SUM(DECODE(session_type, 'FOREGROUND', 1, 0)) / 60)) fcpu,
      to_number((SUM(DECODE(session_type, 'BACKGROUND', 1, 0)) / 60)) bcpu
    FROM
       SYS.V_$active_session_history
    WHERE sample_time   >  sysdate - INTERVAL '1' HOUR
      AND sample_time  <= TRUNC(SYSDATE, 'MI')
      AND session_state = 'ON CPU'
    GROUP BY
       TRUNC(sample_time, 'MI')) ash
 WHERE
    ash.sample_time IS NOT NULL
 ORDER BY
    ash.sample_time;

--

commit;



insert into perfstat.t_waits
SELECT
  to_char(ash.sample_time, 'dd-mm-yyyy hh24:mi') sample_time,
  (ROUND((ash.sample_time - TO_DATE('19700101','yyyymmdd')) * 86400 - TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*3600)) hora,
  round(ash.scheduler,2)   scheduler ,
  round(ash.uio,2)         uio       ,
  round(ash.sio,2)         sio       ,
  round(ash.concurrency,2) concurrency,
  round(ash.application,2) application,
  round(ash.commit,2)      commit    ,
  round(ash.configuration,2) configuration,
  round(ash.administrative,2) administrative,
  round(ash.network,2)     network   ,
  round(ash.queueing,2)    queueing  ,
  round(ash.clust,2)       clust     ,
  round(ash.other,2)       other     ,
  (SELECT MAX(value) FROM SYS.V_$osstat WHERE stat_name = 'NUM_CPUS') num_cpu
 FROM
  (SELECT
     TRUNC(sample_time,'MI')                                sample_time,
     to_number((SUM(DECODE(wait_class, 'Scheduler',      1, 0)) / 60)) scheduler,
     to_number((SUM(DECODE(wait_class, 'User I/O',       1, 0)) / 60)) uio,
     to_number((SUM(DECODE(wait_class, 'System I/O',     1, 0)) / 60)) sio,
     to_number((SUM(DECODE(wait_class, 'Concurrency',    1, 0)) / 60)) concurrency,
     to_number((SUM(DECODE(wait_class, 'Application',    1, 0)) / 60)) application,
     to_number((SUM(DECODE(wait_class, 'Commit',         1, 0)) / 60)) COMMIT,
     to_number((SUM(DECODE(wait_class, 'Configuration',  1, 0)) / 60)) configuration,
     to_number((SUM(DECODE(wait_class, 'Administrative', 1, 0)) / 60)) administrative,
     to_number((SUM(DECODE(wait_class, 'Network',        1, 0)) / 60)) network,
     to_number((SUM(DECODE(wait_class, 'Queueing',       1, 0)) / 60)) queueing,
     to_number((SUM(DECODE(wait_class, 'Cluster',        1, 0)) / 60)) clust,
     to_number((SUM(DECODE(wait_class, 'Other',          1, 0)) / 60)) other
   FROM
      SYS.V_$active_session_history
   WHERE sample_time >  sysdate - INTERVAL '1' HOUR
     AND sample_time <= TRUNC(SYSDATE, 'MI')
   GROUP BY
      TRUNC(sample_time, 'MI')) ash
 WHERE
   ash.sample_time IS NOT NULL
 ORDER BY
   ash.sample_time;


commit;


end;
/

