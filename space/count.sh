count_run_times() {
    tmpresult=$(curl -s "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fraw.ogtt.tk%2Fshell%2Ffunction.sh&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false")
    TODAY_RUN_TIMES=$(echo "$tmpresult" | tail -3 | head -n 1 | awk '{print $5}')
    TOTAL_RUN_TIMES=$(($(echo "$tmpresult" | tail -3 | head -n 1 | awk '{print $7}')))
}
count_run_times
echo -e "${TODAY_RUN_TIMES} / ${TOTAL_RUN_TIMES}"