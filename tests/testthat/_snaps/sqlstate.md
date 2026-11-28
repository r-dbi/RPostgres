# server errors are formatted nicely

    Code
      dbGetQuery(con, "SELECT * FROM no_such_table_579")
    Condition
      Error in `dbSendQuery()`:
      ! Failed to prepare query : ERROR:  relation "no_such_table_579" does not exist

---

    Code
      dbExecute(con,
        "DO $$ BEGIN RAISE EXCEPTION 'boom' USING ERRCODE = 'FS002'; END $$;")
    Condition
      Error in `dbSendQuery()`:
      ! Failed to fetch row : ERROR:  boom

