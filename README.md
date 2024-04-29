# awr_graph
Useful info of ORACLE (awr) visualized with canvas.js

# Previous

**AWR** and **PERFSTAT** (statspack.snap) are running on database (take care with Licensing...)

You must execute on BBDD

> grant select on  SYS.V_$active_session_history to perfstat;

> grant select on  SYS.V_$osstat to perfstat;

With SYS, for example.

# Create Tables and Procedures 

With user **PERFSTAT** you create some tables on BD executing **create_TABLE.sql** file

And then, execute **create_Proc.sql** file to create two proc. on database

# Run the procedures 

Every hour you execute:
> execute PERFSTAT.proc_report_porhora;

every day at > 15:00 (it's harcoded on the proc, get the info from 8h to 15h)
> execute PERFSTAT.proc_report_diario(sysdate);

# On unix server that runs httpd and can connect to DB 

In a directory below a httpd server, you put **canvasjs.min.js** file. You can download from web.

To run the report (i use to put on cron) you have to (daily) execute:

> report.sh


