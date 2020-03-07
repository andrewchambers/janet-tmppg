(import sh)

(defn cleanup-all-servers []
  (each d (->>
            (sh/$$ ["find" "/tmp" "-maxdepth" "1" "-type" "d" "-name" "janet-tmppg.tmp.*"])
            (string/split "\n")
            (map string/trim)
            (filter (comp not empty?)))
    (sh/$? ["pg_ctl" "-s" "-w" "-D" d "stop" "-m" "immediate"])
    (sh/$ ["rm" "-rf" d])))

(defn tmppg
  []
  (def pg-data-dir 
    (string (sh/$$_ ["mktemp" "-d" "/tmp/janet-tmppg.tmp.XXXXX"])))
  (sh/$ ["pg_ctl" "-s" "-D" pg-data-dir "initdb" "-o" "--auth=trust"])
  (sh/$ ["pg_ctl" "-s" "-w" "-D" pg-data-dir  "start" "-l" (string pg-data-dir "/tmppg-log-file.txt")])
  
  @{:connect-string "host=localhost dbname=postgres"
    :close
    (fn [self]
      (sh/$ ["pg_ctl" "-s" "-w" "-D" pg-data-dir "stop" "-m" "immediate"])
      (sh/$ ["rm" "-rf" pg-data-dir])
      nil)})

# Repl helpers
# (import ./tmppg)
# (with [tmppg (tmppg/tmppg)] (pp tmppg))
# (tmppg/cleanup-all-servers)