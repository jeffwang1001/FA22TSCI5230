
library(RPostgres)
library(DBI)

con <- dbConnect(RPostgres::Postgres(),dbname = 'postgres',
                 host = 'db.zgqkukklhncxcctlqpvg.supabase.co',
                 port = 5432,
                 user = 'student',
                 password = 'tsci5230')


dbListTables(con)
dbGetQuery(con, "SELCT = FROM, limit 10)