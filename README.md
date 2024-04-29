# awr_graph
Useful info of ORACLE (awr) visualized with canvas.js

# Welcome!

AWR and PERFSTAT (statspack.snap) are running on database (take care with Licensing...)

You must execute on BBDD

> grant select on  SYS.V_$active_session_history to perfstat;

> grant select on  SYS.V_$osstat to perfstat;

With SYS, for example.

# Create Tables

With user PERFSTAT you create some tables on BD executing *create_TABLE.sql* file




> ALTER SYSTEM SET CONTROL_MANAGEMENT_PACK_ACCESS= "DIAGNOSTIC+TUNING" scope=both;

> execute dbms_workload_repository.modify_snapshot_settings(interval => 60)

And 



Hi! I'm your first Markdown file in **StackEdit**. If you want to learn about StackEdit, you can read me. If you want to play with Markdown, you can edit me. Once you have finished with me, you can create new files by opening the **file explorer** on the left corner of the navigation bar.
