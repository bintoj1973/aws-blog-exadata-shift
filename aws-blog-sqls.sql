SELECT *
FROM   (SELECT sql_id,
               Count(*)
        FROM   gv$active_session_history
        WHERE  event = ‘cell smart table scan’
               AND wait_time = 0
               AND sample_time > sysdate – 60 / 1440
        GROUP  BY sql_id
        ORDER  BY Count(*) DESC); 


SELECT *.
FROM   (
                SELECT   sql_id,
                         count(*)
                FROM     dba_hist_active_sess_history
                WHERE    event = ‘cell smart table scan’
                AND      wait_time = 0
                AND      dbid = &dbid
                AND      snap_id BETWEEN &bsnap AND &esnap
                GROUP BY sql_id
                ORDER BY count(*) DESC);

SELECT sql_id, sql_child_number, sql_exec_id FROM V$ACTIVE_SESSION_HISTORY WHERE sql_id=<SQL ID from Above>; 

SELECT
 ROUND(physical_read_bytes/1048576) phyrd_mb
 ,ROUND(io_cell_offload_eligible_bytes/1048576) io_elg_mb
 ,ROUND(io_interconnect_bytes/1048576) io_ret_mb
 ,(1-(io_interconnect_bytes/NULLIF(physical_read_bytes,0)))*100 “SAVING%” 6 FROM
 v$sql
 WHERE
 sql_id = ‘6a759s0w8933y’
 AND child_number = 0;

WITH TableAccessSQLs AS (
  SELECT DISTINCT sql_id
  FROM V$SQL_PLAN
  WHERE operation LIKE '%TABLE ACCESS STORAGE%'
	OR operation LIKE ‘%STORAGE INDEX%’
),
TopSQLs AS (
  SELECT sql_id, RANK() OVER (ORDER BY <metric> DESC) AS rnk
  FROM DBA_HIST_SQLSTAT
  WHERE sql_id IN (SELECT sql_id FROM TableAccessSQLs)
    AND begin_interval_time >= TO_DATE('start_date', 'YYYY-MM-DD HH24:MI:SS')
    AND end_interval_time <= TO_DATE('end_date', 'YYYY-MM-DD HH24:MI:SS')
)
SELECT sql_id
FROM TopSQLs
WHERE rnk <= <top_n>;


SELECT
   plan_line_id id
    ,LPAD(' ',plan_depth) || plan_operation
    ||' '||plan_options||' '
    ||plan_object_name operation
    ,ROUND(physical_read_bytes /1048576) phy_rd_mb
    ,ROUND(io_interconnect_bytes /1048576) io_ret_mb
    ,(1-(io_interconnect_bytes/NULLIF(physical_read_bytes,0)))*100 "SAVING%"
