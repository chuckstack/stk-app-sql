def show [] {
    psql -Aq -c '\d' --csv | from csv
}

def "show from"  [
    tablename:      string        #table name
    --where (-w):   string        # where clause
    --first (-f):   int           # first clause
] {
    let table_name = $"--set=t=($tablename)"
    let where_clause = if ($where != null) {
        $"--set=w=($where)"
    } else {
        ""
    }

    let first_clause = if ($first != null) {
        $"--set=f=($first)"
    } else {
        ""
    }
    
    psql -Aqt $where_clause $first_clause $table_name -f cli/show.sql | from json
    
}
#NOTE: consider the following when creating a new record and you need to know the uuid for future calls
# from shell; $env.FOO = "me-custom"
#   practical example: order new # creates a new order record and saves the uuid to an environment variable (overriding the lastest)
# from command script: print $env.FOO
